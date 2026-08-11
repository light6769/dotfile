#!/usr/bin/env bash
#
# sync.sh - refresh the repo from your live ~/.config on THIS machine.
#
# Usage:  ./scripts/sync.sh
#
# Copies live configs back into the repo (skipping runtime junk), then
# depersonalizes them so the repo stays publishable and portable:
#   - machine home paths are rewritten to portable forms (__HOME__, $HOME, ~, %h)
#   - the start page username/timezone are stripped
# It never commits or pushes - do that yourself after reviewing.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_PATH="$HOME"

EXCLUDES=( '*.log' 'error.log' 'lyrics' '*.db' 'mpdstate' 'socket' 'node_modules' '.git' '*.wants' 'pipewire-session-manager.service' 'log' )

# copy a live dir into the repo dir, skipping runtime junk
sync_dir() {
    local src="$1" dst="$2"
    local args=()
    for p in "${EXCLUDES[@]}"; do args+=(--exclude="$p"); done
    tar -cf - "${args[@]}" -C "$src" . | tar -xf - -C "$dst"
}

# Config app dirs present in the repo
for d in "$REPO"/config/*/; do
    name="$(basename "$d")"
    [ -d "$HOME/.config/$name" ] || continue
    sync_dir "$HOME/.config/$name" "$d"
    echo "synced config/$name"
done

# Top-level config files (KDE rc files, mimeapps, etc.)
for f in "$REPO"/config/*; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    [ -f "$HOME/.config/$name" ] || continue
    cp "$HOME/.config/$name" "$f"
    echo "synced config/$name"
done

# Home dotfiles
for f in .zshrc .p10k.zsh .bashrc .bash_profile .fehbg opencode.json .gitconfig; do
    [ -f "$HOME/$f" ] && cp "$HOME/$f" "$REPO/home/$f" && echo "synced home/$f"
done

# bin scripts
for s in "$HOME"/.local/bin/*; do
    name="$(basename "$s")"
    cp "$s" "$REPO/bin/$name"
    echo "synced bin/$name"
done

# fonts
sync_dir "$HOME/.local/share/fonts" "$REPO/fonts"
echo "synced fonts/"

# start page
sync_dir "$HOME/.local/share/startup-page" "$REPO/local-share/startup-page"
echo "synced local-share/startup-page/"

echo
echo "Depersonalizing repo (rewriting $HOME_PATH and stripping identity)..."
set +e

# 1. CSS/INI files have no variable expansion -> __HOME__ placeholder
find "$REPO" -type f \( -name 'style.css' -o -name 'config-xpui.ini' \) \
    -exec sed -i "s|$HOME_PATH|__HOME__|g" {} +

# 2. systemd services -> %h
find "$REPO/config/systemd" -type f -name '*.service' \
    -exec sed -i "s|$HOME_PATH|%h|g" {} +

# 3. hyprland + hyprlock configs -> ~ (already the convention there)
find "$REPO/config/hypr" -type f \( -name 'hyprland.conf' -o -name 'hyprlock*.conf' \) \
    -exec sed -i "s|$HOME_PATH|~|g" {} +

# 4. everything else -> $HOME (shell-expandable)
find "$REPO" -type f \
    ! -name 'style.css' ! -name 'config-xpui.ini' \
    ! -name '*.service' \
    ! -name 'hyprland.conf' ! -name 'hyprlock*.conf' \
    -exec sed -i "s|$HOME_PATH|\$HOME|g" {} +

# 5. start page identity + timezone
if [ -f "$REPO/local-share/startup-page/config.js" ]; then
    sed -i "s/name: 'light_roronoa',/name: 'user',/" \
        "$REPO/local-share/startup-page/config.js"
    sed -i "/timeZone:/d" "$REPO/local-share/startup-page/config.js"
fi

set -e
echo
echo "Done. Review with: git -C \"$REPO\" status"
