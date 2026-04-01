# Dotfiles

Personal configuration files managed with Git. One command to set up a new machine.

## Quick Start

```bash
git clone https://github.com/injaeryou/dotfiles.git
cd dotfiles
./install.sh
```

## Structure

```
dotfiles/
├── install.sh              # Main installer (auto-detects OS)
├── git/
│   ├── .gitconfig          # Git config (editor: nano)
│   └── .gitignore_global   # Global gitignore
├── tmux/
│   └── .tmux.conf          # Tmux + TPM plugins
├── uv/
│   └── uv.toml             # uv (14-day package quarantine)
├── npm/
│   └── .npmrc              # npm (14-day min release age)
└── scripts/
    ├── setup-mac.sh        # macOS: Homebrew + packages
    ├── setup-linux.sh      # Linux: apt/dnf/pacman + packages
    └── setup-windows.sh    # Windows: Scoop + psmux
```

## What It Does

- **Detects OS** automatically (macOS / Linux / Windows)
- **Symlinks** config files to the correct locations
- **Backs up** existing files before overwriting
- **Installs packages**: git, tmux, nano, uv
- **Windows**: installs psmux instead of tmux

## Security

Both `uv` and `npm` are configured to exclude packages published within `the last 14 days` to mitigate `supply chain attacks`.
