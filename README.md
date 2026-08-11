# dotfile

Personal Linux dotfiles for Arch Linux (Hyprland).

Includes configs for a full desktop setup - window manager, status bar, launcher,
terminal, notification daemon, media players, editors, file managers, themes,
scripts and fonts - plus a one-command installer to reproduce the setup on a
fresh machine.

## Features

- Hyprland + hyprlock (wallpaper rotation, pywal border colors, resume hook)
- Waybar (custom Kanagawa style, Spotify card + visualizer)
- Rofi, Kitty, Ghostty, Alacritty, foot terminals
- Dunst, Cava, Btop, Fastfetch, Ncmpcpp + MPD
- Neovim, Yazi, Spicetify, EasyEffects, pipewire
- Custom fonts and a browser start page

## Quick install (fresh Arch)

```sh
git clone https://github.com/light6769/dotfile.git ~/.config/dotfile
cd ~/.config/dotfile
./install.sh
```

The installer will:

1. Install base tools (`git`, `base-devel`) and `yay`
2. Add the `chaotic-aur` repository
3. Install all 389 packages (`packages/pacman.txt` + `packages/aur.txt`)
4. Symlink configs into `~/.config`
5. Install user services (hyprland-resume, mpd, pipewire)
6. Link home dotfiles and `~/.local/bin` scripts
7. Install fonts, the start page, and enable system services
8. Set zsh as the default shell

It is idempotent - safe to re-run.

## Structure

```
config/                # mirrors ~/.config
home/                  # $HOME dotfiles (.zshrc, .p10k.zsh, .bashrc, ...)
bin/                   # helper scripts -> ~/.local/bin
fonts/                 # custom fonts -> ~/.local/share/fonts
local-share/           # browser start page
packages/
  pacman.txt           # explicit repo packages
  aur.txt              # AUR packages
  repos.conf           # extra pacman repos
install.sh             # one-command bootstrap
scripts/sync.sh        # pull live configs back into the repo
```

## Keeping it up to date

On this machine, run `./scripts/sync.sh` to copy any live changes back into the
repo, review with `git status`, then commit and push.

## What is intentionally NOT included

- Wallpapers (too large; store them separately)
- Secrets: `.ssh`, `.gnupg`, WireGuard keys, `gh`/copilot auth, browser profiles
- App data/caches: browser profiles, Discord, caches, node_modules
- Machine-specific system configs (`mkinitcpio`, fan control, TLP, GPU env,
  KDE monitor layouts) - adapt these per laptop.

## Post-install

- `p10k configure` - rebuild the prompt if it looks wrong
- `gh auth login` - GitHub auth
- `wal -i <image>` - generate pywal colors for the theme
- `spicetify apply` - apply Spotify theming
- Set your wallpaper directory inside `config/hypr/scripts/`

## License

[MIT](LICENSE)
