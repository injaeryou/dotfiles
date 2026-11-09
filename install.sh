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
if [ "$OS" = "unknown" ]; then
    error "Unsupported OS: $(uname -s)"
    exit 1
fi

# Git Bash의 ln -s는 기본적으로 파일을 복사한다. 네이티브 심링크를 강제
# (Developer Mode 또는 관리자 권한 필요).
if [ "$OS" = "windows" ]; then
    export MSYS=winsymlinks:nativestrict
fi

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

# ─── Claude Code ───
setup_claude() {
    info "Setting up Claude Code..."
    local src="$DOTFILES_DIR/claude/settings.json"
    local dst="$HOME/.claude/settings.json"
    local snapshot="$HOME/.claude/.dotfiles-settings.json"

    mkdir -p "$HOME/.claude"

    link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    link_file "$DOTFILES_DIR/claude/rules" "$HOME/.claude/rules"
    # ~/.claude/skills holds plugin/other skills, so link each skill dir.
    local skill skill_dst
    for skill in "$DOTFILES_DIR"/claude/skills/*/; do
        [ -d "$skill" ] || continue  # glob matched nothing
        skill="${skill%/}"
        skill_dst="$HOME/.claude/skills/$(basename "$skill")"
        # link_file's in-place backup would stay inside skills/ and load
        # as a duplicate skill, so refuse instead.
        if [ -e "$skill_dst" ] && [ ! -L "$skill_dst" ]; then
            error "$skill_dst exists and is not a symlink. Move it out of ~/.claude/skills and re-run."
            exit 1
        fi
        link_file "$skill" "$skill_dst"
    done

    if [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        cp "$src" "$snapshot"
        success "Installed: $dst"
        return
    fi

    # settings.json is merged, not symlinked: Claude Code writes
    # machine-local keys (plugins, hooks, model, ...) into it, and those
    # must not enter the repo. Rules live in scripts/merge_settings.py.
    # Windows Store의 python3.exe 별칭은 실행이 안 되므로, 실제로
    # 동작하는 인터프리터를 골라낸다.
    local py="" candidate
    for candidate in python3 python; do
        if "$candidate" -c 'pass' &>/dev/null; then
            py="$candidate"
            break
        fi
    done
    if [ -z "$py" ]; then
        error "python not found. Cannot merge repo settings into $dst."
        exit 1
    fi

    "$py" "$DOTFILES_DIR/scripts/merge_settings.py" "$dst" "$src" "$snapshot"
    success "Merged repo settings into $dst"
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
    setup_claude
    setup_os_specific

    echo ""
    success "All done!"
}

main "$@"
