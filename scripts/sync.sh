#!/usr/bin/env bash
#
# sync.sh - refresh the repo from your live ~/.config on THIS machine.
#
# Usage:  ./scripts/sync.sh
#
# Copies live configs back into the repo (skipping runtime junk), then prints
# a summary. It never commits or pushes - do that yourself after reviewing.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

EXCLUDES=(
    --exclude='*.log'
    --exclude='error.log'
    --exclude='lyrics'
    --exclude='*.db'
    --exclude='mpdstate'
    --exclude='socket'
    --exclude='node_modules'
    --exclude='.git'
)

# Config app dirs present in the repo
for d in "$REPO"/config/*/; do
    name="$(basename "$d")"
    [ -d "$HOME/.config/$name" ] || continue
    rsync -a "${EXCLUDES[@]}" "$HOME/.config/$name/" "$d"
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
rsync -a "$HOME/.local/share/fonts/" "$REPO/fonts/"
echo "synced fonts/"

# start page
rsync -a "$HOME/.local/share/startup-page/" "$REPO/local-share/startup-page/"
echo "synced local-share/startup-page/"

echo
echo "Done. Review with: git -C \"$REPO\" status"
