# Repository Guidelines

## Project Structure & Module Organization
This repo is a shell function toolkit loaded from `~/.myshell/_init.sh`.

- `_init.sh` bootstraps the environment and sources enabled modules.
- `core/` holds shared paths, exports, aliases, and functions used everywhere.
- `dev/`, `git/`, and `pkg/` group topic-specific helpers.
- `scripts/` contains standalone utilities such as `json_to_block_comment.py`.
- Keep new functions near related code and export only what the shell session needs.

## Build, Test, and Development Commands
There is no package manager or formal build step. Development is source-and-check.

- `source ~/.myshell/_init.sh` reloads the toolkit in a running shell.
- `sh -n _init.sh core/*.sh dev/*.sh git/*.sh pkg/*.sh` checks shell syntax.
- `shellcheck _init.sh core/*.sh dev/*.sh git/*.sh pkg/*.sh` catches portability and quoting issues if `shellcheck` is installed.

## Coding Style & Naming Conventions
Match the surrounding shell style instead of reformatting the whole repo.

- Use `sh`-compatible syntax unless a file already depends on Bash/Zsh features.
- Prefer small, single-purpose functions with descriptive kebab-case names, like `create-dummy-csv` or `git-cleanup-hs`.
- Keep machine-specific values behind variables in `core/paths.sh` or exports, not hardcoded inside functions.
- Follow the file’s existing indentation style; do not mix styles within one block.

## Testing Guidelines
No automated test suite is committed. Validate changes manually.

- Reload the shell and exercise the affected command directly.
- Run syntax checks before opening a PR.
- For functions with side effects, test on disposable data or a throwaway branch first.

## Commit & Pull Request Guidelines
History uses conventional commits, usually `feat(scope): short description`.

- Keep commit messages imperative and scoped, for example `feat(git): add cleanup helper`.
- PRs should explain what changed, which module(s) were touched, and any shell compatibility impact.
- Include example usage or terminal output when behavior changes.
- Note if a change affects Linux, macOS, or package-manager specific helpers under `pkg/`.

## Agent Notes
Do not edit unrelated files or normalize style across the repo. Preserve the lightweight, personal-tooling nature of the project.
