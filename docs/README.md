# Dotfiles Bootstrap

Minimal, idempotent installer that pulls your public dotfiles from **GitHub Releases**, symlinks them into `~/.config/dotfiles/`, and auto-loads them from `~/.bashrc`.

* Sources only files named `aliases_*` and `functions_*`
* Caches downloaded files under `~/.local/share/dotfiles-remote/`
* Clean uninstall (keeps cache)
* Structured logging, retries, timestamps, optional log file
* Release-driven install (immutable versions via tags)

**Repo:** [https://github.com/andranikasd/dotfiles](https://github.com/andranikasd/dotfiles)
**Install source:** GitHub **Releases** assets (e.g., `v1.0.0`)

---

## Quick Start (Release-based)

### Install — latest stable

```bash
curl -fsSL https://github.com/andranikasd/dotfiles/releases/latest/download/setup-dotfiles.sh | bash
```

### Install — pinned to a specific version

```bash
curl -fsSL https://github.com/andranikasd/dotfiles/releases/download/v1.0.0/setup-dotfiles.sh | bash
```

### Uninstall

```bash
curl -fsSL https://github.com/andranikasd/dotfiles/releases/latest/download/setup-dotfiles.sh | UNINSTALL=1 bash
```

> The script adds a loader to `~/.bashrc` that sources `~/.config/dotfiles/aliases_*` and `~/.config/dotfiles/functions_*`.

---

## What gets installed

* **Active dir (symlink targets loaded by `.bashrc`):**
  `~/.config/dotfiles/`

* **Cache dir (immutable copies from the release):**
  `~/.local/share/dotfiles-remote/<OWNER>-<REPO>@<BRANCH>/`

* **Backup dir for `.bashrc` edits:**
  `~/.dotfiles.bak-YYYYMMDD-HHMMSS/`

Your repo content (examples you maintain):

* `aliases_general`, `aliases_git`, `aliases_kube`, `aliases_tf`, …
* (optional) `functions_*` files

---

## Using the aliases (examples)

```bash
ll         # ls -lh with grouping & color
gst        # git status -sb
kgn        # kubectl get nodes -o wide
tfp        # terraform plan
mkcd foo   # mkdir -p foo && cd foo
```

Changes you push to the repo are picked up by **re-running the installer** (same command); it refreshes the cache and relinks files idempotently.

---

## Logging & Controls

Environment variables:

* `DOTFILES_LOG_LEVEL=debug|info|warn|error` (default `info`)
* `DOTFILES_NO_COLOR=1` (disable color)
* `DOTFILES_TIMESTAMPS=1` (prefix logs with timestamps)
* `DOTFILES_LOG_FILE=/path/to/file.log` (also write logs to file; ANSI stripped)
* `DOTFILES_CURL_RETRIES=N` (network retry attempts, default `3`)
* `UNINSTALL=1` (remove loader + symlinks; cache kept)

Examples:

```bash
DOTFILES_LOG_LEVEL=debug DOTFILES_TIMESTAMPS=1 \
  curl -fsSL https://github.com/andranikasd/dotfiles/releases/latest/download/setup-dotfiles.sh | bash

DOTFILES_LOG_FILE=~/dotfiles-install.log \
  curl -fsSL https://github.com/andranikasd/dotfiles/releases/download/v1.0.0/setup-dotfiles.sh | bash
```

---

## How Releases work (maintainers)

This repo uses **semantic-release**:

* PRs merge into `develop`; release PR: `develop → master`
* On push to `master`, semantic-release:

  * analyzes Conventional Commits since the last tag
  * determines SemVer bump (major/minor/patch)
  * updates `CHANGELOG.md`
  * creates a tag `vX.Y.Z` and a **GitHub Release**
  * uploads `setup-dotfiles.sh` as the release asset that installers fetch

**Versioning rules:**

* `feat:` → minor, `fix:`/`perf:` → patch, `feat!:`/`BREAKING CHANGE:` → major
* highest bump wins across commits since the previous tag

**CI guardrails:**

* Trunk Code Quality (linters)
* PR Title Gate (Conventional title + bump guard)
* Gatekeeper waits for required checks before merges to `master`

---

## Testing a release

Test exactly as users do, ideally in a clean environment:

Docker (Debian):

```bash
docker run --rm -it debian:stable bash -lc \
'apt-get update && apt-get install -y curl; \
 curl -fsSL https://github.com/andranikasd/dotfiles/releases/download/v1.0.0/setup-dotfiles.sh | bash; \
 bash -lc "source ~/.bashrc && ll"'
```

WSL (Debian):

```bash
curl -fsSL https://github.com/andranikasd/dotfiles/releases/latest/download/setup-dotfiles.sh | bash
source ~/.bashrc
```

---

## Troubleshooting

* **“No aliases\_* or functions\_* found”\*\*
  Ensure your release/tag contains those files at the repo root (or subdirs — the script auto-discovers paths via the GitHub API).

* **Loader missing**
  Re-run installer; it appends one loader block guarded by markers:
  `# >>> dotfiles aliases/functions loader >>> … <<< dotfiles aliases/functions loader <<<`

* **Protected branch blocks CHANGELOG commit**
  Allow GitHub Actions to write to `master`, or remove `@semantic-release/git` from `.releaserc.json` if you don’t want CHANGELOG commits.

* **Corporate / NAT rate limits**
  The script gracefully works unauthenticated, but you may set `DOTFILES_GITHUB_TOKEN` to increase API limits if needed.

---

## Uninstall completely

```bash
# remove loader & symlinks (keeps cache)
curl -fsSL https://github.com/andranikasd/dotfiles/releases/latest/download/setup-dotfiles.sh | UNINSTALL=1 bash

# optional clean-up
rm -rf ~/.config/dotfiles
rm -rf ~/.local/share/dotfiles-remote
rm -rf ~/.dotfiles.bak-*
```

---

## Contributing

* Follow **Conventional Commits** (`feat:`, `fix:`, `feat!:`, …)
* Run `trunk install && trunk check --fix` before pushing
* Open PRs into `develop`; release via `develop → master`

See `CONTRIBUTING.md` for details.

---

## License

See [LICENSE](LICENSE). By contributing, you agree your contributions are licensed under the repository’s license.