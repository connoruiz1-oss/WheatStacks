#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  WHEATSTACKS RICE -- INSTALL SCRIPT                         ║
# ║                                                              ║
# ║  Creates symlinks from this repo to ~/.config.               ║
# ║  Your existing configs are backed up to ~/.config-backup.    ║
# ║                                                              ║
# ║  Usage: chmod +x install.sh && ./install.sh                  ║
# ║                                                              ║
# ║  What this does:                                             ║
# ║  1. Backs up existing configs                                ║
# ║  2. Creates symlinks so Hyprland/Kitty/etc. read from here   ║
# ║  3. Installs packages (optional, Arch only)                  ║
# ║                                                              ║
# ║  Why symlinks? Because your configs stay in this repo.        ║
# ║  Edit them here, and the apps see the changes immediately.   ║
# ║  You can also version-control your dotfiles with git.        ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
GOLD='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${GOLD}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

# ── Symlink helper ──
# Creates a symlink, backing up any existing file/directory first.
link_config() {
    local src="$DOTFILES_DIR/$1"
    local dst="$CONFIG_DIR/$2"

    # If destination already exists and is not our symlink, back it up
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        warn "Backing up existing $dst to $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/"
    elif [ -L "$dst" ]; then
        rm "$dst"
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"

    ln -sf "$src" "$dst"
    info "Linked $dst -> $src"
}

echo ""
echo -e "${GOLD}  Wheatstacks Rice Installer${NC}"
echo -e "${GOLD}  Inspired by Monet's Stacks of Wheat${NC}"
echo ""

# ── Create symlinks ──
info "Creating symlinks..."

link_config "hypr"             "hypr"
link_config "kitty"            "kitty"
link_config "rofi"             "rofi"
link_config "waybar"           "waybar"
link_config "eww"              "eww"
link_config "fish"             "fish"
link_config "fastfetch"        "fastfetch"
link_config "dunst"            "dunst"

# Starship config goes directly to ~/.config/starship.toml (not a directory)
link_config "starship/starship.toml" "starship.toml"

echo ""
info "Symlinks created!"

# ── Create directories ──
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/Pictures/Wallpapers

# ── Package installation (optional) ──
echo ""
read -p "Install packages with pacman/yay? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Installing core packages..."

    # Core (available in official Arch repos)
    PACMAN_PKGS=(
        hyprland
        hyprlock
        hypridle
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        kitty
        fish
        waybar
        rofi-wayland
        dunst
        hyprpaper
        grim
        slurp
        wl-clipboard
        cliphist
        polkit-gnome
        brightnessctl
        playerctl
        pavucontrol
        thunar
        ttf-jetbrains-mono-nerd
        papirus-icon-theme
        fastfetch
        bat
        eza
        starship
        btop
        jq
    )

    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || warn "Some pacman packages may have failed"

    # AUR packages (requires yay or paru)
    if command -v yay &>/dev/null; then
        info "Installing AUR packages with yay..."
        AUR_PKGS=(
            eww
            hyprpicker
            swappy
            wtype
        )
        yay -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages may have failed"
    elif command -v paru &>/dev/null; then
        info "Installing AUR packages with paru..."
        AUR_PKGS=(
            eww
            hyprpicker
            swappy
            wtype
        )
        paru -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages may have failed"
    else
        warn "No AUR helper found. Install yay or paru, then run:"
        warn "  yay -S eww hyprpicker swappy"
    fi

    echo ""
    info "Packages installed!"
fi

# ── Make scripts executable ──
chmod +x "$DOTFILES_DIR/rofi/scripts/"*.sh 2>/dev/null || true

# ── Done ──
echo ""
info "Installation complete!"
echo ""
echo "  Next steps:"
echo "    1. Set your wallpaper: copy an image to ~/Pictures/Wallpapers/wallpaper.png"
echo "    2. Set your monitor:   edit ~/.config/hypr/hyprland.conf"
echo "    3. Start Hyprland:     add 'exec Hyprland' to your login shell or use a display manager"
echo "    4. Customize:          edit ~/.config/hypr/user.conf for personal tweaks"
echo ""
echo "  Special workspace keybinds:"
echo "    Super+W              Toggle browser"
echo "    Ctrl+Shift+Escape    Toggle system monitor"
echo "    Super+N              Toggle Obsidian"
echo "    Super+\`              Toggle scratchpad"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    warn "Your old configs were backed up to: $BACKUP_DIR"
fi
