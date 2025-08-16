#!/usr/bin/env bash
set -Eeuo pipefail

# Minimal, repo-fixed installer for public GitHub dotfiles
# Repo: https://github.com/andranikasd/dotfiles (branch: master; falls back to main)
# - Lists repo tree via GitHub API, filters aliases_* / functions_*
# - Downloads raw files to a cache, symlinks into ~/.config/dotfiles/
# - Adds a loader block to ~/.bashrc to source them
# Env:
#   UNINSTALL=1  -> remove loader + symlinks (keeps cache)
# Optional:
#   DOTFILES_GITHUB_TOKEN to raise GitHub API rate limits (not required for public)

OWNER="andranikasd"
REPO="dotfiles"
BRANCH="master" # primary (we'll fallback to 'main' if needed)

# ── helpers ───────────────────────────────────────────────────────────────────
msg() { printf "\033[1;32m[dotfiles]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
die() {
	printf "\033[1;31m[err]\033[0m %s\n" "$*"
	exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || die "Missing: $1"; }

need curl
need sed
need awk

STAMP="$(date +%Y%m%d-%H%M%S)"
BK="${HOME}/.dotfiles.bak-${STAMP}"
DOTDIR="${HOME}/.config/dotfiles"
CACHE_DIR="${HOME}/.local/share/dotfiles-remote/${OWNER}-${REPO}@${BRANCH}"
mkdir -p "${BK}" "${DOTDIR}" "${CACHE_DIR}"

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
	[[ -n ${f} ]] && [[ -f ${f} ]] && cp -a -- "${f}" "${BK}/$(basename "${f}")"
}

api_get() {
	local url="$1"
	if [[ -n ${DOTFILES_GITHUB_TOKEN-} ]]; then
		curl -fsSL -H "Authorization: Bearer ${DOTFILES_GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "${url}"
	else
		curl -fsSL -H "Accept: application/vnd.github+json" "${url}"
	fi
}

raw_url() {
	# raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH
	echo "https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/$1"
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
		printf '%s\n' "${sha}"
		return 0
	fi

	if [[ ${BRANCH} == "master" ]]; then
		warn "Branch 'master' not found, trying 'main'…"
		BRANCH="main"
		CACHE_DIR="${HOME}/.local/share/dotfiles-remote/${OWNER}-${REPO}@${BRANCH}"
		mkdir -p "${CACHE_DIR}"
		if sha="$(resolve_branch_sha_once "${BRANCH}")" && [[ -n ${sha} ]]; then
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
		*) : ;; # explicitly ignore non-matching files
		esac
	done
}

download_and_link() {
	local rel base cache dst url canon
	rel="$1"
	base="$(basename "${rel}")"
	cache="${CACHE_DIR}/${base}"
	dst="${DOTDIR}/${base}"
	url="$(raw_url "${rel}")"

	msg "Fetch ${rel}"
	curl -fsSL "${url}" -o "${cache}"
	chmod 0644 "${cache}"

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
		msg "Loader already present (skip)"
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
	fi
}

unlink_installed() {
	shopt -s nullglob
	for f in "${DOTDIR}"/aliases_* "${DOTDIR}"/functions_*; do
		if [[ -L ${f} ]]; then
			msg "Unlink $(basename "${f}")"
			rm -f -- "${f}"
		fi
	done
	shopt -u nullglob
}

# ── main ──────────────────────────────────────────────────────────────────────
if [[ ${UNINSTALL:-0} == "1" ]]; then
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

while IFS= read -r rel; do
	[[ -n ${rel} ]] && download_and_link "${rel}"
done <<<"${targets}"

echo
msg "Done."
echo "Active dir:  ${DOTDIR}"
echo "Cache dir:   ${CACHE_DIR}"
echo "Reload now:  source ~/.bashrc"
