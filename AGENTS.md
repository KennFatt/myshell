# Repository Guidelines

## Project Structure & Module Organization

```
myshell/
├── _init.sh              # Top-level entry point; sources core then enabled modules
├── core/                 # Always-loaded essentials
│   ├── _init.sh          # Sources all core/*.sh and iterates core/functions/*.sh
│   ├── secrets.sh        # Machine-specific secrets (gitignored)
│   ├── dependencies.sh   # Single source of truth: discovers external tools via command -v
│   ├── paths.sh          # PATH additions
│   ├── aliases.sh        # Shell aliases
│   ├── exports.sh        # Environment variable exports
│   └── functions/        # One script per function, auto-sourced by functions.sh
├── dev/                  # Development tooling (aliases, exports, functions)
│   └── _init.sh          # Sources dev/*.sh and dev/functions/*.sh
├── git/                  # Git aliases and helper functions
├── pkg/                  # Package manager wrappers (detects and loads apt/brew/dnf/pacman)
├── scripts/              # Standalone helper scripts
└── assets/               # Static assets (CSS, config templates)
```

Each module follows the same pattern: `_init.sh` as entry point, `aliases.sh`, `functions.sh`, `exports.sh` as siblings, and optional `functions/` directory with one `.sh` file per function.

## Tech Stack

| Technology | Purpose |
|---|---|
| **POSIX sh / bash / zsh** | Target shells; all scripts must be compatible with both bash and zsh |
| **command -v** | Dependency discovery (no hardcoded paths) |
| **shell builtins** | Only standard POSIX utilities and the tools declared in `dependencies.sh` |

## Build, Test, and Development Commands

There is no build step or test suite. Validation is manual.

| Command | What it does | Agent? |
|---|---|---|
| `myshell-doctor` | Checks all 60+ declared dependencies and reports found/missing | **Agents may run this** to verify the environment |
| `source ~/.myshell/_init.sh` | Loads MyShell in the current session | Human-only (modifies shell state) |

## Coding Style & Naming Conventions

- **Indentation**: tabs for shell scripts.
- **Shebang**: `#!/bin/sh` for all scripts. Use POSIX-compatible syntax unless bash/zsh-specific features are required.
- **Compatibility**: Always guard bash/zsh-specific code with `[ -n "$BASH_VERSION" ]` or `[ -n "$ZSH_VERSION" ]` checks. Use `${BASH_SOURCE[0]:-${(%):-%x}}` pattern for script directory resolution.
- **Variable naming**: lowercase with underscores (`tool_bin`, `core_dir`). Dependency discovery variables use `_bin` suffix (`pigz_bin`, `jq_bin`).
- **Function naming**: lowercase with hyphens (`myshell-doctor`, `git-clean-local-branches`). Group related functions into a `functions/` subdirectory under their module.
- **Source guards**: Always use `[ -f "$file" ] && . "$file"` before sourcing optional files to avoid errors on missing files.
- **One function per file** in `functions/` directories. The parent `functions.sh` auto-sources them with a `for f in functions/*.sh` loop.

## Adding a New Module

1. Create a directory under `myshell/` (e.g., `docker/`).
2. Add `_init.sh` inside it to source sibling `*.sh` files and `functions/*.sh`.
3. Register the module name in the `ENABLED_MODULES` array in `_init.sh`.

## Adding a New Function

1. Create a single `.sh` file inside the relevant module's `functions/` directory.
2. Define exactly one function in that file.
3. The function is automatically sourced when the module loads (no other wiring needed).

## Dependency Manifest

`core/dependencies.sh` is the single source of truth for all external tool paths. Every tool is discovered via `command -v` and stored in a `${name}_bin` variable. The `myshell-doctor` function iterates `MDS_CATEGORIES` to report availability. When adding a new dependency:

1. Add a `name_bin="$(path_of name)"` line in the appropriate category section.
2. Add the variable to the corresponding `MDS_CATEGORIES` entry.
