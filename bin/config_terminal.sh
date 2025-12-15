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
else
    echo "✓ Base packages installed successfully"
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
            if chmod +x $TERMINAL_CONFIG/nvim.sh && sh $TERMINAL_CONFIG/nvim.sh; then
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
if mkdir -p ohmyzsh && cd ohmyzsh && \
   curl -fsLO https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh && \
   sed -i 's/exec zsh -l/#exec zsh -l/g' ./install.sh && \
   sh ./install.sh && \
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

# Theme
echo "Installing Powerlevel10k theme..."
if git clone https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>/dev/null; then
    echo "✓ Powerlevel10k theme installed successfully"
else
    echo "✗ Failed to install Powerlevel10k theme (may already exist)"
fi

# Plugins
echo "Installing zsh plugins..."
PLUGIN_SUCCESS=true
if ! git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null; then
    echo "✗ Failed to install zsh-syntax-highlighting (may already exist)"
    PLUGIN_SUCCESS=false
fi

if ! git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null; then
    echo "✗ Failed to install zsh-autosuggestions (may already exist)"
    PLUGIN_SUCCESS=false
fi

if [ "$PLUGIN_SUCCESS" = true ]; then
    echo "✓ Zsh plugins installed successfully"
fi

# Copy configuration files
echo "Copying configuration files..."
if [ -f $HOME/.zshrc ]; then
    cp $HOME/.zshrc $HOME/.zshrc_bckp
    echo "✓ Backed up existing .zshrc to .zshrc_bckp"
fi
if cp $TERMINAL_CONFIG/.zshrc $HOME/.zshrc; then
    echo "✓ Copied .zshrc"
else
    echo "✗ Failed to copy .zshrc"
    FAILED_INSTALLS+=(".zshrc configuration")
fi

if [ -f $HOME/.p10k.zsh ]; then
    cp $HOME/.p10k.zsh $HOME/.p10k.zsh_bckp
    echo "✓ Backed up existing .p10k.zsh to .p10k.zsh_bckp"
fi
if cp $TERMINAL_CONFIG/.p10k.zsh $HOME/.p10k.zsh; then
    echo "✓ Copied .p10k.zsh"
else
    echo "✗ Failed to copy .p10k.zsh"
    FAILED_INSTALLS+=(".p10k.zsh configuration")
fi

# Fonts
echo "Installing fonts..."
if chmod +x $TERMINAL_CONFIG/font.sh && sh $TERMINAL_CONFIG/font.sh; then
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
