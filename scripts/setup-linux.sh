#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }

info "Starting Linux setup..."

# ─── Detect package manager ───
if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
    PKG_INSTALL="sudo apt-get install -y"
    PKG_UPDATE="sudo apt-get update"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="sudo dnf install -y"
    PKG_UPDATE="sudo dnf check-update || true"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    PKG_INSTALL="sudo pacman -S --noconfirm"
    PKG_UPDATE="sudo pacman -Sy"
else
    warn "Unsupported package manager. Please install manually."
    exit 1
fi

info "Package manager: $PKG_MANAGER"
$PKG_UPDATE

# ─── Packages ───
PACKAGES=(
    git
    tmux
    nano
)

info "Installing packages..."
for pkg in "${PACKAGES[@]}"; do
    if command -v "$pkg" &>/dev/null; then
        success "$pkg already installed"
    else
        info "Installing $pkg..."
        $PKG_INSTALL "$pkg" || warn "$pkg install failed - skipping"
    fi
done

# ─── rtk (official install script) ───
if ! command -v rtk &>/dev/null; then
    info "Installing rtk..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    success "rtk installed"
else
    success "rtk already installed"
fi

# ─── uv (official install script) ───
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    success "uv installed"
else
    success "uv already installed"
fi
