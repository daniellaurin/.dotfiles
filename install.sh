#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# In Coder, module "dotfiles" can run before bootstrap_workspace installs stow;
# exit 0 so bootstrap_workspace invokes this script cleanly once stow is installed.
if ! command -v stow >/dev/null 2>&1; then
  echo "stow not installed yet; skipping until bootstrap completes."
  exit 0
fi

# Remove non-symlink defaults that would block Stow
for f in "$HOME/.zshrc" "$HOME/.tmux.conf"; do
  [ -f "$f" ] && [ ! -L "$f" ] && rm -f "$f"
done

# Pre-create directories so --no-folding keeps runtime plugins/caches out of .dotfiles
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.tmux/plugins"

# Stow core headless packages (Arch, Coder, KVM)
cd "$DOTFILES_DIR"
for pkg in zsh starship tmux git vscodium scripts; do
  [ -d "$pkg" ] && stow --no-folding -R -t "$HOME" "$pkg"
done

# Future desktop-only packages (Kitty, Hyprland) when running on Arch / KVM GUI
if [ -d "$DOTFILES_DIR/desktop" ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }; then
  for pkg in kitty hypr; do
    [ -d "$DOTFILES_DIR/desktop/$pkg" ] && stow --no-folding -R -d "$DOTFILES_DIR/desktop" -t "$HOME" "$pkg"
  done
fi

# Clone separate Neovim config repo (init.lua) directly into ~/.config/nvim
if [ ! -d "$HOME/.config/nvim/.git" ]; then
  if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
  fi
  git clone https://github.com/daniellaurin/init.lua.git "$HOME/.config/nvim" || true
fi

# Install TPM (Tmux Plugin Manager) & plugins on fresh boxes
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || true
fi
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
fi
