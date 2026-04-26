#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }

info "Starting Windows (Git Bash / MSYS2) setup..."

# ─── Check Git Bash / MSYS2 ───
if [[ "$(uname -s)" != MINGW* ]] && [[ "$(uname -s)" != MSYS* ]]; then
    warn "Please run this in Git Bash or MSYS2."
    warn "If using WSL, run setup-linux.sh instead."
    exit 1
fi

# ─── Scoop (Windows package manager) ───
if command -v scoop &>/dev/null; then
    success "Scoop already installed"
else
    info "Installing Scoop..."
    powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"
    success "Scoop installed"
fi

# ─── Packages ───
PACKAGES=(
    git
    nano
    uv
)

# ─── rtk (download pre-built binary) ───
if ! command -v rtk &>/dev/null; then
    info "Installing rtk..."
    RTK_DIR="$HOME/.local/bin"
    mkdir -p "$RTK_DIR"
    RTK_URL="$(curl -fsSL https://api.github.com/repos/rtk-ai/rtk/releases/latest | grep -o 'https://.*rtk-x86_64-pc-windows-msvc.zip')"
    if [ -n "$RTK_URL" ]; then
        curl -fsSL "$RTK_URL" -o /tmp/rtk.zip
        unzip -o /tmp/rtk.zip -d "$RTK_DIR"
        rm -f /tmp/rtk.zip
        success "rtk installed to $RTK_DIR"
        warn "Make sure $RTK_DIR is in your PATH"
    else
        warn "rtk download failed - install manually from https://github.com/rtk-ai/rtk/releases"
    fi
else
    success "rtk already installed"
fi

# ─── psmux (tmux alternative for Windows) ───
info "Installing psmux..."
if ! powershell -Command "Get-Module -ListAvailable -Name psmux" &>/dev/null 2>&1; then
    powershell -Command "Install-Module -Name psmux -Scope CurrentUser -Force"
    success "psmux installed"
else
    success "psmux already installed"
fi

info "Installing packages..."
for pkg in "${PACKAGES[@]}"; do
    if scoop list "$pkg" &>/dev/null 2>&1; then
        success "$pkg already installed"
    else
        info "Installing $pkg..."
        scoop install "$pkg" || warn "$pkg install failed - skipping"
    fi
done
