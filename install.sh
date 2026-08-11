#!/usr/bin/env bash
#
# Personal dotfiles installer.
# Restores packages, configs, fonts, scripts and services on a fresh Arch Linux box.
#
# Usage:
#   git clone https://github.com/light6769/dotfile.git ~/.config/dotfile
#   cd ~/.config/dotfile && ./install.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
HOME_SRC="$REPO_DIR/home"
BIN_SRC="$REPO_DIR/bin"
FONTS_SRC="$REPO_DIR/fonts"
PKG_SRC="$REPO_DIR/packages"
STARTPAGE_SRC="$REPO_DIR/local-share/startup-page"

C_G='\033[32m'; C_B='\033[34m'; C_R='\033[31m'; C_NC='\033[0m'
msg()  { printf "${C_G}[*]${C_NC} %s\n" "$1"; }
info() { printf "${C_B}[i]${C_NC} %s\n" "$1"; }
warn() { printf "${C_R}[!]${C_NC} %s\n" "$1"; }
die()  { warn "$1"; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Do not run this script as root."

msg "dotfiles installer"
echo

# 1. Base tools ----------------------------------------------------------------
msg "Installing base tools (git, base-devel)..."
sudo pacman -S --needed --noconfirm git base-devel

# 2. AUR helper (yay) ----------------------------------------------------------
if ! command -v yay >/dev/null 2>&1; then
    msg "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
fi

# 3. Extra pacman repos (chaotic-aur) ------------------------------------------
if [ -f "$PKG_SRC/repos.conf" ]; then
    msg "Adding chaotic-aur repository..."
    if ! pacman -Q chaotic-keyring >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm chaotic-keyring chaotic-mirrorlist || true
    fi
    if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
        sudo sed -i '$a\# added by dotfiles installer' /etc/pacman.conf
        while read -r line; do
            [ -n "$line" ] && sudo sed -i "\$a$line" /etc/pacman.conf
        done < "$PKG_SRC/repos.conf"
    fi
    sudo pacman -Sy
fi

# 4. Packages ------------------------------------------------------------------
if [ -f "$PKG_SRC/pacman.txt" ]; then
    msg "Installing $(wc -l < "$PKG_SRC/pacman.txt") pacman packages..."
    sudo pacman -S --needed --noconfirm - < "$PKG_SRC/pacman.txt"
fi

if [ -f "$PKG_SRC/aur.txt" ]; then
    msg "Installing $(wc -l < "$PKG_SRC/aur.txt") AUR packages..."
    yay -S --needed --noconfirm - < "$PKG_SRC/aur.txt"
fi

# 5. Install ~/.config apps ----------------------------------------------------
#    Symlinked where possible; configs using the __HOME__ placeholder are copied
#    and the placeholder substituted with the real home directory (CSS/INI files
#    cannot expand variables themselves).
msg "Installing configs into ~/.config..."
mkdir -p "$HOME/.config"
for entry in "$CONFIG_SRC"/*; do
    name="$(basename "$entry")"
    [ "$name" = "systemd" ] && continue
    target="$HOME/.config/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        warn "~/.config/$name already exists and is not a symlink -> skipping"
        continue
    fi
    rm -f "$target"
    if grep -rIl '__HOME__' "$entry" >/dev/null 2>&1; then
        cp -r "$entry" "$target"
        grep -rl '__HOME__' "$target" | xargs -r sed -i "s|__HOME__|$HOME|g"
    else
        ln -sfn "$entry" "$target"
    fi
done

# 6. User systemd services ------------------------------------------------------
msg "Installing user services (hyprland-resume, mpd)..."
mkdir -p "$HOME/.config/systemd/user"
cp -r "$CONFIG_SRC/systemd/user"/*.service "$HOME/.config/systemd/user/" 2>/dev/null || true
systemctl --user daemon-reload
systemctl --user enable --now hyprland-resume.service 2>/dev/null || true
systemctl --user enable --now mpd.service 2>/dev/null || true
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber 2>/dev/null || true

# 7. Home dotfiles --------------------------------------------------------------
msg "Linking home dotfiles..."
for entry in "$HOME_SRC"/* "$HOME_SRC"/.[!.]*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    ln -sfn "$entry" "$HOME/$name"
done

# 8. Scripts --------------------------------------------------------------------
msg "Installing scripts into ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
for script in "$BIN_SRC"/*; do
    [ -e "$script" ] || continue
    chmod +x "$script"
    ln -sfn "$script" "$HOME/.local/bin/$(basename "$script")"
done

# 9. Fonts ----------------------------------------------------------------------
msg "Installing fonts..."
mkdir -p "$HOME/.local/share/fonts"
cp -r "$FONTS_SRC"/. "$HOME/.local/share/fonts/"
fc-cache -f >/dev/null 2>&1

# 10. Browser start page --------------------------------------------------------
if [ -d "$STARTPAGE_SRC" ]; then
    msg "Installing start page..."
    mkdir -p "$HOME/.local/share/startup-page"
    cp -r "$STARTPAGE_SRC"/. "$HOME/.local/share/startup-page/"
fi

# 11. System services -----------------------------------------------------------
msg "Enabling system services..."
sudo systemctl enable --now sddm NetworkManager bluetooth 2>/dev/null || true

# 12. Default shell -------------------------------------------------------------
msg "Setting zsh as default shell..."
if ! grep -q "^$USER:.*zsh" /etc/passwd; then
    sudo chsh -s /bin/zsh "$USER"
fi

echo
msg "Done!"
echo
info "Post-install steps:"
info "  - Run 'p10k configure' to rebuild the Powerlevel10k prompt."
info "  - Run 'gh auth login' to authenticate GitHub."
info "  - Run 'spotify' + 'spicetify apply' for Spotify theming."
info "  - Generate pywal colors: 'wal -i /path/to/wallpaper'"
info "  - If wallpaper scripts are used, set your wallpaper dir in config/hypr/scripts/."
