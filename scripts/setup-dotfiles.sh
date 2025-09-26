#!/usr/bin/env bash
set -Eeuo pipefail

# Minimal, repo-fixed installer for public GitHub dotfiles
# Repo: https://github.com/andranikasd/dotfiles (branch: master; falls back to main)
# - Lists repo tree via GitHub API, filters aliases_* / functions_*
# - Downloads raw files to a cache, symlinks into ~/.config/dotfiles/
# - Adds a loader block to ~/.bashrc to source them
# Env:
#   UNINSTALL=1            -> remove loader + symlinks (keeps cache)
#   DOTFILES_LOG_LEVEL     -> debug|info|warn|error  (default info)
#   DOTFILES_NO_COLOR=1    -> disable colors
#   DOTFILES_TIMESTAMPS=1  -> add timestamps to logs
#   DOTFILES_LOG_FILE=FILE -> append logs to FILE
#   DOTFILES_CURL_RETRIES  -> curl retries (default 3)

OWNER="andranikasd"
REPO="dotfiles"
BRANCH="master" # primary (we'll fallback to 'main' if needed)

# ── logging ───────────────────────────────────────────────────────────────────
_log_level_num() {
	case "${DOTFILES_LOG_LEVEL:-info}" in
	debug) printf '10' ;;
	info) printf '20' ;;
	warn) printf '30' ;;
	error) printf '40' ;;
	*) printf '20' ;; # default info
	esac
}

LOG_LEVEL_NUM="$(_log_level_num)"
LOG_TTY=0
[[ -t 1 ]] && LOG_TTY=1
LOG_COLOR=1
[[ ${DOTFILES_NO_COLOR:-0} == "1" ]] && LOG_COLOR=0
# Colors (only if TTY & not disabled)
if [[ ${LOG_TTY} -eq 1 ]] && [[ ${LOG_COLOR} -eq 1 ]]; then
	C_RESET=$'\033[0m'
	C_GREEN=$'\033[1;32m'
	C_YELLOW=$'\033[1;33m'
	C_RED=$'\033[1;31m'
	C_BLUE=$'\033[1;34m'
else
	C_RESET=""
	C_GREEN=""
	C_YELLOW=""
	C_RED=""
	C_BLUE=""
fi

_ts() {
	if [[ ${DOTFILES_TIMESTAMPS:-0} == "1" ]]; then
		date +"%Y-%m-%d %H:%M:%S "
	else
		printf ''
	fi
}

_log_emit() {
	local _ts
	_current_ts="$(_ts)"
	# $1 level-num, $2 prefix(colorized), $3 message
	if [[ $1 -lt ${LOG_LEVEL_NUM} ]]; then return 0; fi
	if [[ -n ${DOTFILES_LOG_FILE-} ]]; then
		# strip ANSI for file
		# Strip ANSI colors from the level string
		level_clean="$(printf '%s' "$2" | sed 's/\x1b\[[0-9;]*m//g')"

		# Store the message
		msg="$3"

		# Append to the log file
		printf '%s[%s] %s\n' "${_current_ts}" "${level_clean}" "${msg}" >>"${DOTFILES_LOG_FILE}"
	fi
	printf '%s%s%s %s%s\n' "${_current_ts}" "$2" "${C_RESET}" "$3" "" 1>&2
}

log_debug() { _log_emit 10 "${C_BLUE}[debug]" "$*"; }
log_info() { _log_emit 20 "${C_GREEN}[info]" "$*"; }
log_warn() { _log_emit 30 "${C_YELLOW}[warn]" "$*"; }
log_error() { _log_emit 40 "${C_RED}[err]" "$*"; }

# Back-compat wrappers (keep existing call sites)
msg() { log_info "$*"; }
warn() { log_warn "$*"; }
die() {
	log_error "$*"
	exit 1
}

# ── helpers ───────────────────────────────────────────────────────────────────
need() { command -v "$1" >/dev/null 2>&1 || die "Missing: $1"; }
need curl
need sed
need awk

CURL_RETRIES="${DOTFILES_CURL_RETRIES:-3}"
CURL_BASE_OPTS=(-fsSL --retry "${CURL_RETRIES}" --retry-delay 1)

STAMP="$(date +%Y%m%d-%H%M%S)"
BK="${HOME}/.dotfiles.bak-${STAMP}"
DOTDIR="${HOME}/.config/dotfiles"
CACHE_DIR="${HOME}/.local/share/dotfiles-remote/${OWNER}-${REPO}@${BRANCH}"
mkdir -p "${BK}" "${DOTDIR}" "${CACHE_DIR}"

log_debug "OWNER=${OWNER} REPO=${REPO} BRANCH=${BRANCH}"
log_debug "DOTDIR=${DOTDIR} CACHE_DIR=${CACHE_DIR}"
log_debug "CURL_RETRIES=${CURL_RETRIES}"

LOADER_START="# >>> dotfiles aliases/functions loader >>>"
LOADER_END="# <<< dotfiles aliases/functions loader <<<"
LOADER="$(
	cat <<'EOS'
# >>> dotfiles aliases/functions loader >>>
DOTFILES_DIR="$HOME/.config/dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
  shopt -s nullglob
  for file in "$DOTFILES_DIR"/aliases_* "$DOTFILES_DIR"/functions_*; do
    [ -f "$file" ] && . "$file"
  done
  shopt -u nullglob
fi
# <<< dotfiles aliases/functions loader <<<
EOS
)"

backup() {
	local f="${1-}"
	if [[ -n ${f} ]] && [[ -f ${f} ]]; then
		cp -a -- "${f}" "${BK}/$(basename "${f}")"
		log_debug "Backed up $(basename "${f}") to ${BK}"
	fi
}

api_get() {
	local url="$1"
	if [[ -n ${DOTFILES_GITHUB_TOKEN-} ]]; then
		curl "${CURL_BASE_OPTS[@]}" -H "Authorization: Bearer ${DOTFILES_GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "${url}"
	else
		curl "${CURL_BASE_OPTS[@]}" -H "Accept: application/vnd.github+json" "${url}"
	fi
}

raw_url() {
	# raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH
	printf 'https://raw.githubusercontent.com/%s/%s/%s/%s' "${OWNER}" "${REPO}" "${BRANCH}" "$1"
}

resolve_branch_sha_once() {
	local branch api
	branch="$1"
	api="https://api.github.com/repos/${OWNER}/${REPO}/branches/${branch}"
	api_get "${api}" | sed -n 's/.*"sha": *"\([0-9a-f]\{7,\}\)".*/\1/p' | head -n1
}

resolve_branch_sha() {
	local sha
	if sha="$(resolve_branch_sha_once "${BRANCH}")" && [[ -n ${sha} ]]; then
		log_info "Resolved branch '${BRANCH}' -> ${sha}"
		printf '%s\n' "${sha}"
		return 0
	fi
	if [[ ${BRANCH} == "master" ]]; then
		warn "Branch 'master' not found, trying 'main'…"
		BRANCH="main"
		CACHE_DIR="${HOME}/.local/share/dotfiles-remote/${OWNER}-${REPO}@${BRANCH}"
		mkdir -p "${CACHE_DIR}"
		if sha="$(resolve_branch_sha_once "${BRANCH}")" && [[ -n ${sha} ]]; then
			log_info "Resolved branch 'main' -> ${sha}"
			printf '%s\n' "${sha}"
			return 0
		fi
	fi
	return 1
}

list_paths() {
	local sha api
	sha="$1"
	api="https://api.github.com/repos/${OWNER}/${REPO}/git/trees/${sha}?recursive=1"
	api_get "${api}" | sed -n 's/.*"path": *"\([^"]\+\)".*/\1/p'
}

filter_targets() {
	# stdin: repo paths; stdout: only aliases_* / functions_* paths
	while IFS= read -r p; do
		[[ -z ${p} ]] && continue
		case "${p##*/}" in
		aliases_* | functions_*)
			printf '%s\n' "${p}"
			;;
		*) : ;;
		esac
	done
}

download_and_link() {
	local rel base cache dst url canon size
	rel="$1"
	base="$(basename "${rel}")"
	cache="${CACHE_DIR}/${base}"
	dst="${DOTDIR}/${base}"
	url="$(raw_url "${rel}")"

	msg "Fetch ${rel}"
	# download with retries
	curl "${CURL_BASE_OPTS[@]}" "${url}" -o "${cache}"
	chmod 0644 "${cache}"
	size="$(wc -c <"${cache}" 2>/dev/null || printf '0')"
	log_debug "Downloaded ${base} (${size} bytes) -> ${cache}"

	if [[ -L ${dst} ]] || [[ -f ${dst} ]]; then
		if [[ -L ${dst} ]]; then
			if canon="$(readlink -f -- "${dst}")"; then
				if [[ ${canon} == "${cache}" ]]; then
					msg "Link OK: ${base}"
					return 0
				fi
			fi
		fi
		rm -f -- "${dst}"
		ln -s -- "${cache}" "${dst}"
		msg "Relink: ${base}"
	else
		ln -s -- "${cache}" "${dst}"
		msg "Link  : ${base}"
	fi
}

add_loader() {
	if ! grep -qF "${LOADER_START}" "${HOME}/.bashrc" 2>/dev/null; then
		msg "Add loader to ~/.bashrc"
		backup "${HOME}/.bashrc"
		printf '\n%s\n' "${LOADER}" >>"${HOME}/.bashrc"
	else
		log_debug "Loader already present in ~/.bashrc"
	fi
}

remove_loader() {
	if grep -qF "${LOADER_START}" "${HOME}/.bashrc" 2>/dev/null; then
		msg "Remove loader from ~/.bashrc"
		backup "${HOME}/.bashrc"
		awk -v s="${LOADER_START}" -v e="${LOADER_END}" '
      $0 ~ s {inblk=1; next}
      $0 ~ e {inblk=0; next}
      !inblk {print}
    ' "${HOME}/.bashrc" >"${HOME}/.bashrc.tmp" && mv "${HOME}/.bashrc.tmp" "${HOME}/.bashrc"
	else
		log_debug "Loader not found in ~/.bashrc (skip remove)"
	fi
}

unlink_installed() {
	shopt -s nullglob
	local found=0
	for f in "${DOTDIR}"/aliases_* "${DOTDIR}"/functions_*; do
		if [[ -L ${f} ]]; then
			found=1
			msg "Unlink $(basename "${f}")"
			rm -f -- "${f}"
		fi
	done
	shopt -u nullglob
	[[ ${found} -eq 0 ]] && log_debug "No symlinks to unlink in ${DOTDIR}"
}

# ── main ──────────────────────────────────────────────────────────────────────
if [[ ${UNINSTALL:-0} == "1" ]]; then
	msg "Uninstall requested"
	remove_loader
	unlink_installed
	msg "Uninstalled. Cache kept at: ${CACHE_DIR}"
	exit 0
fi

add_loader

sha="$(resolve_branch_sha)"
[[ -n ${sha} ]] || die "Failed to resolve branch SHA for ${OWNER}/${REPO}@${BRANCH}"

all_paths="$(list_paths "${sha}")"
targets="$(printf '%s\n' "${all_paths}" | filter_targets)"
if [[ -z ${targets} ]]; then
	warn "No aliases_* or functions_* files found in ${OWNER}/${REPO}@${BRANCH}"
	exit 0
fi

# count & log targets
target_count="$(printf '%s\n' "${targets}" | sed '/^$/d' | wc -l | tr -d ' ')"
log_info "Found ${target_count} target file(s) to install"

while IFS= read -r rel; do
	[[ -n ${rel} ]] && download_and_link "${rel}"
done <<<"${targets}"

echo
msg "Done."
echo "Active dir:  ${DOTDIR}"
echo "Cache dir:   ${CACHE_DIR}"
echo "Reload now:  source ~/.bashrc"
