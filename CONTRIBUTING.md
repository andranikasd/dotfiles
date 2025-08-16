# Contributing to andranikasd/dotfiles

Thanks for helping improve this dotfiles/setup project! This guide explains how we work, how to propose changes, and how releases happen.

---

## TL;DR

* Use **Conventional Commits** for every commit/PR title (`feat: …`, `fix: …`, `feat!: …` or `BREAKING CHANGE:` when breaking).
* Open PRs from `feature/*` or `hotfix/*` ➜ into `develop`. We release only after merging `develop` ➜ `master`.
* Make CI happy:

  * `trunk install && trunk check --fix` locally.
  * Ensure **PR title** follows Conventional Commits (the bot will check).
* **Do not tag releases** manually. They’re created automatically on `master`.

---

## Branching & Release Model

* Work happens on short-lived branches: `feature/<topic>` or `hotfix/<topic>`.
* Merge **feature/hotfix ➜ develop** (squash/merge/rebase allowed; keep conventional messages).
* When we’re ready to release, open **develop ➜ master**.
* On push to `master`, **semantic-release**:

  * Calculates the next **SemVer** from commit messages since the last tag.
  * Generates release notes and updates `CHANGELOG.md`.
  * Creates a tag (e.g. `v1.2.3`) and a GitHub Release.
  * Uploads `setup-dotfiles.sh` as a release asset.

### How the version is decided

* **major**: any commit with `!` after the type (`feat!:`), or a `BREAKING CHANGE:` paragraph.
* **minor**: any `feat:` commit.
* **patch**: any `fix:` or `perf:` commit.
* **no release**: only `docs:`, `chore:`, `refactor:`, `style:`, `test:`, etc.

The **highest level** seen since the previous tag wins.

---

## Commit / PR Title Convention

We follow **Conventional Commits**. Examples:

`feat(kube): show context+ns in prompt`
`fix(tf): handle backend init race`
`docs(readme): add install one-liner`
`refactor: split log helpers`
`feat!: drop legacy installer`

**Squash merges:** the **PR title becomes the merge commit**. Make sure the PR title accurately reflects the highest bump (add `!` or `BREAKING CHANGE:` when needed). CI enforces PR title format and compares it to the commits.

---

## Local Dev & Linters

This repo uses **Trunk** to orchestrate linters/formatters (ShellCheck, shfmt, etc).

Before pushing:

1. Run `trunk install`
2. Run `trunk check --fix`
3. Ensure scripts are POSIX/Bash-safe and idempotent.

---

## Tests / Manual Checks

For now we rely on CI + manual smoke:

* Run `setup-dotfiles.sh` locally in a fresh Debian/WSL shell.
* Verify:

  * `~/.config/dotfiles` populated and symlinks created.
  * Loader snippet appended once to `~/.bashrc`.
  * Re-running is idempotent.
  * Uninstall flow: `UNINSTALL=1 bash setup-dotfiles.sh` removes links & loader.

---

## Opening a Pull Request

1. Branch from `develop`:

   ```
   git switch develop
   git pull
   git switch -c feature/<short-topic>
   ```
2. Commit using Conventional Commits.
3. Push & open PR into `develop`.
4. Make CI green:

   * **Trunk Code Quality**
   * **Conventional PR Title**
   * **Bump Guard (Title ≥ Commits)**
5. Get at least one review; address comments.

### Release PR (develop ➜ master)

* Prefer a **merge commit** (keeps all individual commit messages).
* If your repo enforces **squash**, set the PR title to the highest bump in the batch (e.g., `feat!:` if any breaking, else `feat:`, else `fix:`).

---

## CI / Gatekeeper

Merges to the default branch are blocked until:

* **Trunk Code Quality** passes
* **Conventional PR Title** passes
* **Bump Guard (Title ≥ Commits)** passes
* **Gatekeeper** confirms all of the above are green

These are configured as **required status checks** on `master`.

---

## Releasing & Installing

* Releases are created **automatically** on merge to `master`.
* Users install from GitHub Releases (immutable):

  * Latest:

    ```
    curl -fsSL https://github.com/andranikasd/dotfiles/releases/latest/download/setup-dotfiles.sh | bash
    ```
  * Specific version:

    ```
    curl -fsSL https://github.com/andranikasd/dotfiles/releases/download/vX.Y.Z/setup-dotfiles.sh | bash
    ```

---

## Code of Conduct

Be kind and constructive. If you see behavior that violates community standards, open an issue or contact a maintainer.

---

## License

See [LICENSE](LICENSE). By contributing, you agree your contributions are licensed under the repository’s license.