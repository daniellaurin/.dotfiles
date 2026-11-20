#!/bin/bash

CSV_FILE="../pkg/progs.csv"

# 1. Detect the system's package manager
if command -v pacman &>/dev/null; then
  PM="sudo pacman -S --needed --noconfirm"
elif command -v apt-get &>/dev/null; then
  sudo apt-get update
  PM="sudo apt-get install -y"
else
  echo "No supported package manager found."
  exit 1
fi

# 2. Read the CSV and route the installation
while IFS=',' read -r tag package purpose; do
  # Skip the header line and empty lines
  [[ "$tag" == "#"* ]] || [[ -z "$package" ]] && continue

  echo "Installing: $package ($purpose)"

  if [[ "$tag" == "F" ]]; then
    # Route to Flatpak
    flatpak install -y flathub "$package"
  elif [[ "$tag" == "A" ]]; then
    # Route to AUR helper (assuming it is installed)
    yay -S --needed --noconfirm "$package"
  else
    # Route to the native system package manager
    $PM "$package"
  fi
done <"$CSV_FILE"
