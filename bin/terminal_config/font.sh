#!/bin/bash

# Resolve script directory for relative file paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Installing MesloLGS NF Fonts"
echo "=========================================="
echo ""

# Detect if running in WSL
IS_WSL=false
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    IS_WSL=true
    echo "⚠ WSL (Windows Subsystem for Linux) detected!"
    echo ""
fi

# Create and enter temporary directory
if ! mkdir -p font_tmp; then
    echo "✗ ERROR: Failed to create font_tmp directory"
    exit 1
fi

if ! cd font_tmp; then
    echo "✗ ERROR: Failed to enter font_tmp directory"
    rm -rf font_tmp
    exit 1
fi

# Download fonts
echo "Downloading MesloLGS NF fonts..."
FONTS=(
    "MesloLGS%20NF%20Regular.ttf"
    "MesloLGS%20NF%20Bold.ttf"
    "MesloLGS%20NF%20Italic.ttf"
    "MesloLGS%20NF%20Bold%20Italic.ttf"
)

DOWNLOAD_FAILED=false
for font in "${FONTS[@]}"; do
    echo -n "  Downloading ${font//%20/ }... "
    if wget -q "https://github.com/romkatv/powerlevel10k-media/raw/master/$font"; then
        echo "✓"
    else
        echo "✗ Failed"
        DOWNLOAD_FAILED=true
    fi
done

if [ "$DOWNLOAD_FAILED" = true ]; then
    echo ""
    echo "✗ Some fonts failed to download. Check your internet connection."
    cd ..
    rm -rf font_tmp
    exit 1
fi

# Install fonts in Linux
echo ""
echo "Installing fonts to ~/.local/share/fonts..."
if ! mkdir -p ~/.local/share/fonts; then
    echo "✗ ERROR: Failed to create fonts directory"
    cd ..
    rm -rf font_tmp
    exit 1
fi

if ! mv *.ttf ~/.local/share/fonts/; then
    echo "✗ ERROR: Failed to move fonts"
    cd ..
    rm -rf font_tmp
    exit 1
fi

echo "✓ Fonts copied successfully"

# Update font cache
echo ""
echo "Updating font cache..."
if fc-cache -f -v > /dev/null 2>&1; then
    echo "✓ Font cache updated"
else
    echo "⚠ Warning: Failed to update font cache"
fi

# Verify installation
echo ""
echo "Verifying installation..."
if fc-list | grep -qi "meslo"; then
    echo "✓ MesloLGS NF fonts are now available"
else
    echo "⚠ Warning: Fonts may not be properly installed"
fi

# Return to parent directory
if ! cd ..; then
    echo "✗ ERROR: Failed to return to parent directory"
    exit 1
fi

rm -rf font_tmp

echo ""
echo "=========================================="
echo "Configuration Instructions"
echo "=========================================="
echo ""

# Configure terminal based on environment and available terminals
if [ "$IS_WSL" = true ]; then
    # WSL-specific instructions
    echo "📌 WSL DETECTED - Important Windows Terminal Configuration:"
    echo ""
    echo "The fonts have been installed in Linux, but you need to configure"
    echo "Windows Terminal to use them:"
    echo ""
    echo "Option 1 - Install fonts in Windows (RECOMMENDED):"
    echo "  1. Download fonts from your Windows file explorer:"
    echo "     \\\\wsl\$\\<distro-name>\\home\\$USER\\.local\\share\\fonts\\"
    echo "  2. Or download directly from:"
    echo "     https://github.com/romkatv/powerlevel10k-media/raw/master/"
    echo "  3. Right-click each .ttf file and select 'Install' (or 'Install for all users')"
    echo ""
    echo "Option 2 - Configure Windows Terminal:"
    echo "  1. Open Windows Terminal settings (Ctrl+,)"
    echo "  2. Select your WSL profile"
    echo "  3. Appearance → Font face → Select 'MesloLGS NF'"
    echo "  4. Save and restart terminal"
    echo ""
    echo "Alternative terminals (VS Code, IntelliJ, etc.):"
    echo "  - Set terminal font to: MesloLGS NF"
    echo ""

elif command -v gnome-terminal > /dev/null; then
    # GNOME Terminal detected
    echo "🖥️  GNOME Terminal detected"
    echo ""
    
    if [ -f "$SCRIPT_DIR/gterminal.preferences" ]; then
        echo "Applying GNOME Terminal profile settings..."
        if dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < "$SCRIPT_DIR/gterminal.preferences" 2>/dev/null; then
            echo "✓ Terminal profile configured successfully"
            echo ""
            echo "Close and re-open this terminal to see the changes."
        else
            echo "⚠ Could not apply terminal profile automatically"
            echo ""
            echo "Please configure manually:"
            echo "  1. Open Terminal Preferences"
            echo "  2. Select your profile"
            echo "  3. Set custom font to: MesloLGS NF Regular"
        fi
    else
        echo "⚠ GNOME Terminal preferences file not found"
        echo ""
        echo "Please configure the font manually:"
        echo "  1. Open Terminal → Preferences"
        echo "  2. Select your profile"
        echo "  3. Enable 'Custom font'"
        echo "  4. Choose: MesloLGS NF Regular"
    fi
    echo ""

else
    # Other terminals
    echo "🖥️  Terminal Configuration Required"
    echo ""
    echo "The fonts have been installed successfully."
    echo "Please configure your terminal to use them:"
    echo ""
    echo "For most terminals:"
    echo "  1. Open terminal preferences/settings"
    echo "  2. Find the font/appearance section"
    echo "  3. Set font to: MesloLGS NF Regular"
    echo "  4. Save and restart terminal"
    echo ""
    echo "Popular terminals:"
    echo "  • Konsole: Settings → Edit Current Profile → Appearance → Font"
    echo "  • Terminator: Right-click → Preferences → Profiles → Font"
    echo "  • Alacritty: Edit ~/.config/alacritty/alacritty.yml → font.normal.family"
    echo "  • Kitty: Edit ~/.config/kitty/kitty.conf → font_family"
    echo ""
fi

echo "=========================================="
echo "✓ Font installation complete!"
echo "=========================================="
