<div align="center">

<img src="assets/hacker.gif" alt="pixel art hacker" width="100%">

# s1mple-Dotfiles

My Parrot / bspwm setup, installed with a single command.

`bspwm` · `sxhkd` · `polybar` · `picom` · `rofi` · `feh` · `zsh + powerlevel10k` · `tmux` · `MATE Terminal`

</div>

---

## Quick install

```bash
git clone https://github.com/avivyap/s1mple-Dotfiles
cd s1mple-Dotfiles
chmod +x install.sh
./install.sh
```

Run it as your **normal user**, not as root. It calls `sudo` only when it needs it. When it finishes, restart bspwm (`bspc wm -r`) or log out and back in, and pick the **bspwm** session at the login screen.

Requirements: a Debian-based system with `apt` (Parrot, Debian, Kali, Ubuntu) and an internet connection.

## What it installs

| Component | What it does |
|---|---|
| bspwm + sxhkd | Window manager and keybindings (apt, compiled from source if apt does not have them) |
| polybar | Status bar, with my modules (`bin/` scripts) |
| picom | Compositor for transparencies |
| rofi | Launcher, with the Arc-Dark theme |
| feh | Wallpaper |
| zsh + powerlevel10k | Shell, prompt and plugins |
| tmux | oh-my-tmux config |
| MATE Terminal | Terminal profile (transparent background, Hack Nerd Font) |
| Hack Nerd Font | Font used by the terminal and the bar |
| bat, lsd | Better `cat` and `ls` |

## What the script does

- Installs the packages quietly and prints one status line per step. The full details go to `~/install-dotfiles.log`.
- **Backs up** anything it replaces to `~/dotfiles-backup-<date>`, so you can run it more than once.
- Copies the configs to `~/.config`, the scripts to `~/.config/bin` and the wallpapers to `~/wallpaper`.
- Detects virtual machines and installs the matching guest tools (VMware, VirtualBox, KVM/QEMU).
- Finishes with a check of the whole setup, listing anything that failed.

## Virtual machines

picom can cause graphic glitches in some VMs, such as windows that do not repaint until you do something else. In **VMware**, turn off **Accelerate 3D graphics** in the VM settings (with the VM powered off). That fixed it for me.

If it still fails, the installer asks whether to enable picom when it detects a VM. You can also decide without being asked:

```bash
PICOM_ON=0 ./install.sh
```

With `PICOM_ON=0`, picom is disabled and polybar uses pseudo-transparency.

## Structure

```
.
├── install.sh        installer
├── .config/          bspwm, sxhkd, polybar, picom, rofi theme, zsh, terminal profile
├── bin/              scripts used by polybar
├── fonts/            Hack Nerd Font
└── wallpapers/
```

## Credits

- [powerlevel10k](https://github.com/romkatv/powerlevel10k) by romkatv
- [oh-my-tmux](https://github.com/gpakosz/.tmux) by gpakosz
- Everything else in this repo is built on top of Parrot OS.
