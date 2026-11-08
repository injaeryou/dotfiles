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

    mkdir -p "$HOME/.claude"

    link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

    if [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        success "Installed: $dst"
        return
    fi

    # Merge repo settings into the machine file. Repo values win on
    # conflict; dicts merge recursively; machine-local keys (plugins,
    # hooks, model, ...) are preserved and never enter the repo.
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
        warn "python not found. Skipping settings.json merge."
        return
    fi

    if "$py" - "$dst" "$src" <<'EOF'
import json, sys
dst, src = sys.argv[1], sys.argv[2]

def merge(base, over):
    out = dict(base)
    for k, v in over.items():
        out[k] = merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out

merged = merge(json.load(open(dst, encoding="utf-8")),
               json.load(open(src, encoding="utf-8")))
with open(dst, "w", encoding="utf-8") as f:
    json.dump(merged, f, indent=2, ensure_ascii=False)
    f.write("\n")
EOF
    then
        success "Merged repo settings into $dst"
    else
        warn "Merge failed (invalid JSON in $dst?). Left untouched."
    fi
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
