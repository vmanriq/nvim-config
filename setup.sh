#!/usr/bin/env bash
# Quick setup de la config de Neovim en una máquina nueva (macOS).
# Uso:
#   git clone git@github.com:<user>/nvim-config.git ~/.config/nvim
#   cd ~/.config/nvim && ./setup.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED="$HOME/.config/nvim"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*"; }

if [ "$REPO_DIR" != "$EXPECTED" ]; then
  warn "El repo está en $REPO_DIR, se esperaba $EXPECTED"
  warn "Clónalo ahí: git clone <repo-url> ~/.config/nvim"
  exit 1
fi

# 1. Homebrew + paquetes
if ! command -v brew >/dev/null; then
  warn "Homebrew no instalado. Instálalo primero: https://brew.sh"
  exit 1
fi
info "Instalando paquetes de Brewfile…"
brew bundle --file "$REPO_DIR/Brewfile"

# 2. npm globals (LSP/linter/formatter de TS)
if command -v npm >/dev/null; then
  npm_install_if_missing() {
    local bin="$1" pkg="$2"
    if ! command -v "$bin" >/dev/null 2>&1; then
      info "npm install -g $pkg"
      npm install -g "$pkg"
    fi
  }
  npm_install_if_missing typescript-language-server typescript-language-server
  npm_install_if_missing eslint_d eslint_d
  npm_install_if_missing prettierd @fsouza/prettierd
else
  warn "npm no encontrado — instala node (brew o nvm) y corre: npm i -g typescript-language-server eslint_d @fsouza/prettierd"
fi

# 3. Helpers de worktree (funciones zsh usadas por el dashboard de nvim)
info "Symlink de shell/worktree.zsh → ~/.config/zsh/worktree.zsh"
mkdir -p "$HOME/.config/zsh"
ln -sf "$REPO_DIR/shell/worktree.zsh" "$HOME/.config/zsh/worktree.zsh"
if ! grep -q 'worktree.zsh' "$HOME/.zshrc" 2>/dev/null; then
  warn "Agrega a tu ~/.zshrc:  source ~/.config/zsh/worktree.zsh"
fi

# 4. Checks no fatales
info "Verificando auth de GitHub…"
gh auth status || warn "Corre: gh auth login  (necesario para octo.nvim / PR review)"

info "Verificando AWS CLI…"
if aws --version >/dev/null 2>&1; then
  [ -f "$HOME/.aws/config" ] || warn "Configura tus perfiles SSO en ~/.aws/config (aws configure sso)"
else
  warn "aws CLI no disponible"
fi

info "Listo. Abre 'nvim' — lazy.nvim instalará los plugins desde lazy-lock.json."
