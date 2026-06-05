#!/bin/bash

TERMINAL_CONFIG="./terminal_config"

AUTOMATIC_START=$1

# Track failed installations
FAILED_INSTALLS=()

# Update package lists (ignore errors from unsigned repositories)
echo "Updating package lists..."
if ! sudo apt update -y 2>&1; then
    echo "⚠ Warning: apt update had some issues. Continuing anyway..."
fi

echo "Installing base packages (curl, wget, zsh)..."
if ! sudo apt install -y curl wget zsh; then
    echo "✗ Failed to install base packages (curl, wget, zsh)"
    FAILED_INSTALLS+=("base packages")
    echo "Exiting due to failure in installing base packages."
    exit 1
else
    echo "✓ Base packages installed successfully"
fi

# Change default shell to zsh
echo "Changing default shell to zsh..."
if [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "/bin/zsh" ]; then
    echo "✓ Default shell is already zsh"
else
    if sudo chsh -s /usr/bin/zsh "$USER"; then
        echo "✓ Default shell changed to zsh"
    else
        echo "✗ Failed to change default shell to zsh"
        FAILED_INSTALLS+=("default shell change to zsh")
    fi
fi

# Install EZA
echo "Installing EZA..."
if sudo apt install -y gpg && \
   sudo mkdir -p /etc/apt/keyrings && \
   wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
   echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list && \
   sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
   sudo apt update && \
   sudo apt install -y eza; then
    echo "✓ EZA installed successfully"
else
    echo "✗ Failed to install EZA"
    FAILED_INSTALLS+=("EZA")
fi

# Install Batcat
echo "Installing Batcat..."
if sudo apt install -y bat; then
    echo "✓ Batcat installed successfully"
else
    echo "✗ Failed to install Batcat"
    FAILED_INSTALLS+=("Batcat")
fi

# Install Most
echo "Installing Most..."
if sudo apt install -y most; then
    echo "✓ Most installed successfully"
else
    echo "✗ Failed to install Most"
    FAILED_INSTALLS+=("Most")
fi

# Install Neovim
echo "Would you like to install neovim at the latest version, with lazyvim configuration? [y|n]"

while :
do
    if [ "$AUTOMATIC_START" == "true" ]; then
        res="y"
        echo "Automatic installation started."
    else
        read -n 1 res
        echo ""  # Add newline after reading single character
    fi
    
    case $res in
        y|Y)
            echo "Installing Neovim..."
            if chmod +x "$TERMINAL_CONFIG/nvim.sh" && sh "$TERMINAL_CONFIG/nvim.sh"; then
                echo "✓ Neovim installed successfully"
            else
                echo "✗ Failed to install Neovim"
                FAILED_INSTALLS+=("Neovim")
            fi
            break
        ;;
        n|N)
            echo "Skipping Neovim installation."
            break
        ;;
        *)
            echo "Please type 'y' or 'n'"
        ;;
    esac
done

# Oh-my-zsh
echo "Installing Oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✓ Oh-my-zsh is already installed, skipping"
else
    if mkdir -p ohmyzsh && cd ohmyzsh && \
       curl -fsLO https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh && \
       sed -i 's/exec zsh -l/#exec zsh -l/g' ./install.sh && \
       sh ./install.sh --unattended && \
       rm ./install.sh && \
       cd .. && \
       rm -rf ohmyzsh; then
        echo "✓ Oh-my-zsh installed successfully"
    else
        echo "✗ Failed to install Oh-my-zsh"
        FAILED_INSTALLS+=("Oh-my-zsh")
        cd .. 2>/dev/null
        rm -rf ohmyzsh 2>/dev/null
    fi
fi

# Theme
echo "Installing Powerlevel10k theme..."
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
    echo "✓ Powerlevel10k theme already installed, updating..."
    git -C "$P10K_DIR" pull --quiet 2>/dev/null || echo "⚠ Could not update Powerlevel10k"
else
    if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" 2>/dev/null; then
        echo "✓ Powerlevel10k theme installed successfully"
    else
        echo "✗ Failed to install Powerlevel10k theme"
        FAILED_INSTALLS+=("Powerlevel10k")
    fi
fi

# Plugins
echo "Installing zsh plugins..."
PLUGIN_SUCCESS=true

ZSH_HIGHLIGHT_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
if [ -d "$ZSH_HIGHLIGHT_DIR" ]; then
    echo "✓ zsh-syntax-highlighting already installed, updating..."
    git -C "$ZSH_HIGHLIGHT_DIR" pull --quiet 2>/dev/null || echo "⚠ Could not update zsh-syntax-highlighting"
else
    if ! git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_HIGHLIGHT_DIR" 2>/dev/null; then
        echo "✗ Failed to install zsh-syntax-highlighting"
        PLUGIN_SUCCESS=false
    fi
fi

ZSH_AUTOSUGGEST_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [ -d "$ZSH_AUTOSUGGEST_DIR" ]; then
    echo "✓ zsh-autosuggestions already installed, updating..."
    git -C "$ZSH_AUTOSUGGEST_DIR" pull --quiet 2>/dev/null || echo "⚠ Could not update zsh-autosuggestions"
else
    if ! git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGEST_DIR" 2>/dev/null; then
        echo "✗ Failed to install zsh-autosuggestions"
        PLUGIN_SUCCESS=false
    fi
fi

if [ "$PLUGIN_SUCCESS" = true ]; then
    echo "✓ Zsh plugins installed successfully"
fi

# Copy configuration files
echo "Copying configuration files..."
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc_bckp"
    echo "✓ Backed up existing .zshrc to .zshrc_bckp"
fi
if cp "$TERMINAL_CONFIG/.zshrc" "$HOME/.zshrc"; then
    echo "✓ Copied .zshrc"
else
    echo "✗ Failed to copy .zshrc"
    FAILED_INSTALLS+=(".zshrc configuration")
fi

if [ -f "$HOME/.p10k.zsh" ]; then
    cp "$HOME/.p10k.zsh" "$HOME/.p10k.zsh_bckp"
    echo "✓ Backed up existing .p10k.zsh to .p10k.zsh_bckp"
fi
if cp "$TERMINAL_CONFIG/.p10k.zsh" "$HOME/.p10k.zsh"; then
    echo "✓ Copied .p10k.zsh"
else
    echo "✗ Failed to copy .p10k.zsh"
    FAILED_INSTALLS+=(".p10k.zsh configuration")
fi

# Fonts
echo "Installing fonts..."
if chmod +x "$TERMINAL_CONFIG/font.sh" && sh "$TERMINAL_CONFIG/font.sh"; then
    echo "✓ Fonts installed successfully"
else
    echo "✗ Failed to install fonts"
    FAILED_INSTALLS+=("Fonts")
fi

echo ""
echo "=========================================="
if [ ${#FAILED_INSTALLS[@]} -eq 0 ]; then
    echo "✓ Installation complete! All components installed successfully."
else
    echo "⚠ Installation completed with some issues:"
    for item in "${FAILED_INSTALLS[@]}"; do
        echo "  - $item"
    done
fi
echo "=========================================="
echo ""
echo "Close and re-open the terminal. Then run 'zsh' and have a nice day!"
