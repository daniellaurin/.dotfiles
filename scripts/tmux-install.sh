#!/usr/bin/env bash

echo "1. Installing Arch Linux dependencies..."
sudo pacman -S --needed tmux git xdg-utils fzf fd ttf-jetbrains-mono-nerd

echo "2. Copying tmux configuration files..."
mkdir -p ~/.config/tmux
cp ~/Clone/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
cp ~/Clone/.dotfiles/tmux/.config/tmux/tmux-nerd-font-window-name.yml ~/.config/tmux/

echo "3. Checking for Tmux Plugin Manager (TPM)..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
  echo "TPM is already installed."
fi

echo "Done! Launch 'tmux' and press 'Ctrl+b' then 'Shift+i' (capital I) to install plugins."
