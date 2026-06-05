#!/bin/bash

# Install Neovim

# Check if neovim is already installed
if command -v nvim &> /dev/null; then
    echo "✓ Neovim is already installed: $(nvim --version | head -1)"
    echo "Skipping Neovim installation."
else
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    ./nvim.appimage --appimage-extract

    if [ -d /squashfs-root ]; then
        sudo rm -rf /squashfs-root
    fi
    sudo mv squashfs-root /

    if [ -L /usr/bin/nvim ] || [ -f /usr/bin/nvim ]; then
        sudo rm -f /usr/bin/nvim
    fi
    sudo ln -s /squashfs-root/AppRun /usr/bin/nvim

    # Clean up
    rm -f nvim.appimage

    echo "✓ Neovim installed: $(nvim --version | head -1)"
fi

# Configure LazyVim
if [ -d "$HOME/.config/nvim" ]; then
    echo "✓ Neovim configuration already exists, skipping LazyVim setup"
else
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    echo "✓ LazyVim configuration installed"
fi