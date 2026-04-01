#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ─── Detect OS ───
detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "mac" ;;
        Linux*)   echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

OS="$(detect_os)"
info "Detected OS: $OS"

# ─── Create symlink ───
link_file() {
    local src="$1"
    local dst="$2"

    if [ -L "$dst" ]; then
        local current_target
        current_target="$(readlink "$dst")"
        if [ "$current_target" = "$src" ]; then
            success "Already linked: $dst"
            return
        fi
        warn "Replacing existing symlink: $dst"
        rm "$dst"
    elif [ -e "$dst" ]; then
        local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
        warn "Backing up existing file: $dst -> $backup"
        mv "$dst" "$backup"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    success "Linked: $dst -> $src"
}

# ─── Git ───
setup_git() {
    info "Setting up Git..."
    link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
    link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
}

# ─── Tmux ───
setup_tmux() {
    info "Setting up Tmux..."
    link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

    # Install TPM
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        info "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        success "TPM installed"
    else
        success "TPM already installed"
    fi
}

# ─── uv ───
setup_uv() {
    info "Setting up uv..."

    local uv_config_dir
    case "$OS" in
        mac|linux) uv_config_dir="$HOME/.config/uv" ;;
        windows)   uv_config_dir="$APPDATA/uv" ;;
    esac

    if [ -f "$DOTFILES_DIR/uv/uv.toml" ]; then
        link_file "$DOTFILES_DIR/uv/uv.toml" "$uv_config_dir/uv.toml"
    else
        warn "uv/uv.toml not found. Skipping."
    fi
}

# ─── npm ───
setup_npm() {
    info "Setting up npm..."
    link_file "$DOTFILES_DIR/npm/.npmrc" "$HOME/.npmrc"
}

# ─── OS-specific setup ───
setup_os_specific() {
    local script="$DOTFILES_DIR/scripts/setup-${OS}.sh"
    if [ -f "$script" ]; then
        info "Running OS-specific setup: $script"
        bash "$script"
    fi
}

# ─── Main ───
main() {
    echo ""
    echo "========================================="
    echo "  Dotfiles Installer"
    echo "  OS: $OS"
    echo "========================================="
    echo ""

    setup_git
    if [ "$OS" != "windows" ]; then
        setup_tmux
    fi
    setup_uv
    setup_npm
    setup_os_specific

    echo ""
    success "All done!"
}

main "$@"
