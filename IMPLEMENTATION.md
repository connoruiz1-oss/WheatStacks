# Wheatstacks Rice: Implementation Plan

A phased build plan for turning a Dell OptiPlex 3070 into a stable, customized
Linux workstation running EndeavourOS + Hyprland. Designed around three
priorities, in order:

1. **Stability first.** Every phase ends with a bootable machine you can log
   into. No phase leaves you stranded.
2. **Offload the Mac.** The end state moves documents, Obsidian, and compute
   off your MacBook so you can wipe it and keep it for light use.
3. **Rice second.** Aesthetics come after the machine is usable. Hyprland is
   the goal, but never the blocker.

---

## 0. Decisions Register

Every decision already made, with a one-line rationale so future-you knows why.

| Decision          | Choice                     | Why                                                                             |
| ----------------- | -------------------------- | ------------------------------------------------------------------------------- |
| Distro            | EndeavourOS                | Arch underneath, sane defaults on top. Best teacher-to-friction ratio.          |
| Desktop           | Hyprland                   | Wayland compositor with the aesthetics you want.                                |
| Fallback desktop  | XFCE (installed alongside) | Safety net. Log in here when a Hyprland config breaks your session.             |
| Display manager   | SDDM                       | Works cleanly with Wayland, lets you pick session (Hyprland / XFCE) at login.   |
| Shell             | Fish                       | Beginner-friendly, already configured in this repo.                             |
| Prompt            | Starship                   | Already configured.                                                             |
| Terminal          | Kitty                      | Already configured.                                                             |
| Launcher          | Rofi (rofi-wayland)        | Your config already uses it. Richer than wofi.                                  |
| Editor            | Neovim + nano              | nvim primary, nano kept for moments when you do not want to think.              |
| Notifications     | Dunst                      | Simple, already referenced in `exec.conf`.                                      |
| Wallpaper daemon  | hyprpaper                  | Native Hyprland, lighter than swww. No fade transitions, but we don't use them. |
| Lock / idle       | hyprlock + hypridle        | Native Hyprland stack.                                                          |
| Dotfiles          | Git, tracked from day one  | Version history is your rollback mechanism.                                     |
| Disk              | Single boot, no LUKS       | Simplest install. Revisit encryption if the machine ever travels.               |
| File sharing      | Syncthing + SSH            | Mac-to-OptiPlex sync, works over LAN or Tailscale.                              |
| Remote access     | Tailscale                  | Zero-config VPN so you can reach the OptiPlex from your Mac anywhere.           |
| Local LLM runtime | Ollama                     | Easiest path to Gemma / Llama on CPU. Small models only on UHD 630.             |

---

## 1. Hardware Prep (before the OptiPlex arrives)

Things you can do now so the install day is fast.

### 1.1 Build a live USB

1. Download the latest EndeavourOS ISO from https://endeavouros.com/.
2. On your Mac, use [balenaEtcher](https://etcher.balena.io/) or `dd` to flash
   an 8GB+ USB stick. balenaEtcher is the low-stakes option.
3. Verify the checksum. EndeavourOS publishes SHA512 sums next to the ISO.
   `shasum -a 512 EndeavourOS*.iso` on the Mac, compare to the published value.

### 1.2 Push `wheatstacks-rice` to git

You want this repo reachable from the OptiPlex on install day. Pick one:

- **GitHub private repo** (recommended). Create an empty private repo, then
  from this folder on your Mac:
  ```
  cd ~/path/to/wheatstacks-rice
  git init
  git add .
  git commit -m "Initial rice"
  git branch -M main
  git remote add origin git@github.com:<you>/wheatstacks-rice.git
  git push -u origin main
  ```
- **Self-hosted**: skip for now, revisit once the OptiPlex is up.

### 1.3 Decide on WiFi

The OptiPlex 3070 SFF often ships without a WiFi card.

- If the OptiPlex will sit next to your router, just use ethernet. Simplest.
- If you need WiFi, order an Intel AX200 M.2 card plus antennas (cheap,
  drop-in, supported by the kernel out of the box).

### 1.4 BIOS sanity checklist

When the machine arrives, press `F2` at the Dell logo and set:

- **Secure Boot**: Disabled.
- **SATA Operation**: AHCI (not RAID).
- **Boot mode**: UEFI only (not Legacy).
- **Fastboot**: Thorough (lets the USB be detected).
- Save and exit.

### 1.5 Mac-side inventory (do this while you wait)

Before you start offloading to the OptiPlex you need to know what you are
moving. Make a list on the Mac:

- Total size of `~/Documents`, `~/Obsidian`, `~/Downloads`, any media folders.
- Any apps whose data lives outside those (Photos library, browser profiles
  you care about, iMessage archives, etc.).
- Cloud-synced folders (iCloud, Dropbox, Google Drive): note which you want
  to keep on the Mac vs. migrate.

This list feeds Phase 5.

---

## 2. Phase 1: Base Install (45 min, produces a bootable machine)

Goal: a working EndeavourOS system with XFCE. No rice yet. If you stop after
this phase you still have a usable computer.

### 2.1 Boot the installer

1. Plug in USB, ethernet, keyboard, mouse, monitor.
2. Power on, hammer `F12` for the one-time boot menu.
3. Pick the USB. EndeavourOS live environment boots.

### 2.2 Run the Calamares installer

Choose **Online** install (gets you latest packages).

Key choices:

- **Keyboard**: US (or whatever you use).
- **Partitions**: "Erase disk". No swap needed if you have 16GB+ RAM; pick
  swap-to-file if you want hibernate later. Filesystem: **ext4** (boring,
  bulletproof; BTRFS is fine too but has more moving parts if you are new).
- **Users**: your username, strong password, machine hostname (e.g.
  `wheatstacks`).
- **Desktop**: select **Xfce**. This is your fallback. You will add Hyprland
  manually in Phase 2 so you learn how it fits together.
- **Packages**: leave defaults, plus tick "Firefox" if offered.

Install, reboot, pull the USB.

### 2.3 First-boot housekeeping

Log into XFCE. Open a terminal.

```bash
# Update everything
sudo pacman -Syu

# Install yay (AUR helper) if not already present
sudo pacman -S --needed base-devel git

# Core dev + quality-of-life tools
sudo pacman -S --needed neovim nano fish starship kitty \
  git openssh rsync curl wget unzip tmux htop btop fastfetch \
  bat eza fd ripgrep jq

# Make fish your shell (log out and back in after)
chsh -s /usr/bin/fish
```

Reboot. You should now log in and land in XFCE with fish as your shell.

**Checkpoint**: you have a working Linux desktop. Everything from here is
additive.

---

## 3. Phase 2: Hyprland Layer (60 min)

Goal: install Hyprland + the rice stack, applied via `install.sh`. XFCE stays
installed as your safety net.

### 3.1 Clone your dotfiles

```bash
mkdir -p ~/Code
cd ~/Code
git clone git@github.com:<you>/wheatstacks-rice.git
# or https:// if you have not set up an SSH key yet
```

(SSH key setup: `ssh-keygen -t ed25519 -C "your@email"`, add the public key
at https://github.com/settings/keys.)

### 3.2 Run the installer

```bash
cd ~/Code/wheatstacks-rice
chmod +x install.sh
./install.sh
```

Answer **yes** when it asks about packages. This pulls Hyprland, rofi-wayland,
waybar, eww, dunst, swww, and friends.

### 3.3 Install the display manager

```bash
sudo pacman -S --needed sddm
sudo systemctl enable sddm
```

**Do not reboot yet** if XFCE's default display manager (lightdm) was
running. Disable it first:

```bash
sudo systemctl disable lightdm
```

### 3.4 Add the fallback wallpaper

Drop any image at `~/Pictures/Wallpapers/wallpaper.png` so swww has something
to load on first Hyprland launch.

### 3.5 Reboot, pick Hyprland at the SDDM greeter

At the login screen, top-left dropdown switches sessions. Pick Hyprland.

If Hyprland crashes or you see a black screen: Ctrl+Alt+F2 drops you to a TTY,
log in, and either fix the config or log back into XFCE from the greeter.
This is the safety net the whole phased plan was designed around.

### 3.6 Config gaps to fill in this phase

The current rice repo is missing a few pieces your `exec.conf` and
`keybinds.conf` expect. Create these before rebooting into Hyprland (see §8):

- `hypr/hyprlock.conf` (Super+Delete binds to `hyprlock`).
- `hypr/hypridle.conf` (hypridle is installed but unconfigured).
- `dunst/dunstrc` (dunst is launched but reads its default config).

---

## 4. Phase 3: Core Workflow (30 min)

Goal: the day-to-day apps are installed and configured.

```bash
# Browsers and tools
yay -S --needed firefox obsidian-bin 1password zen-browser-bin

# Dev stack
sudo pacman -S --needed docker docker-compose nodejs npm python python-pip \
  python-pipx lazygit github-cli
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # log out and back in for this to take effect

# Neovim starter config (pick ONE)
#   LazyVim:  easy, opinionated
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

Sign into Firefox, Obsidian, 1Password, GitHub CLI (`gh auth login`).

**Checkpoint**: you can browse, take notes, code, and run containers.

---

## 5. Phase 4: Homelab + Network (45 min)

Goal: make the OptiPlex reachable and useful from the Mac.

### 5.1 SSH

```bash
sudo systemctl enable --now sshd
```

From the Mac: `ssh-copy-id user@optiplex.local` (or the OptiPlex IP). Test:
`ssh user@optiplex.local`.

### 5.2 Tailscale

```bash
yay -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

Follow the auth URL on the Mac. Both machines now see each other by
`<hostname>.<tailnet>.ts.net` no matter what network you are on.

### 5.3 Syncthing

```bash
sudo pacman -S syncthing
systemctl --user enable --now syncthing.service
```

Open `http://localhost:8384`, pair the Mac's Syncthing. Share the folders
you want to move (Obsidian vault, documents).

### 5.4 Storage plan

The 3070 SFF has room for:

- One M.2 NVMe (boot / root).
- One 2.5" SATA (data).

If you ordered a second drive, format it as ext4 and mount at `/mnt/data`.
Point Syncthing at `/mnt/data/sync` so the SSD is not your sync target.

---

## 6. Phase 5: Mac Offload (time varies)

Goal: move the bulk off the Mac so you can wipe it.

Order matters. Do it in passes.

### 6.1 First pass: low-risk bulk

- Downloads, old screenshots, video files, rough notes. Syncthing or `rsync`
  over Tailscale. Verify on the OptiPlex, delete from the Mac.

### 6.2 Second pass: Obsidian vault

- Syncthing the vault, two-way. Open it on both machines, confirm writes
  propagate. After a week of parallel use you can call the OptiPlex the
  primary.

### 6.3 Third pass: documents and project files

- `rsync -avh --progress ~/Documents/ optiplex:/mnt/data/Documents/`.
- Once confirmed, delete from the Mac.

### 6.4 Fourth pass: credentials and secrets

- 1Password handles this naturally. Just make sure you are logged in on the
  OptiPlex before you wipe the Mac.

### 6.5 Wipe the Mac

- Reinstall macOS from Recovery (Cmd+R at boot). Set it up as a new machine
  with only the apps you need for mobile work (browser, 1Password, Obsidian
  for read-access to the synced vault).

---

## 7. Phase 6: Local LLM (optional, 30 min)

Goal: run a small model locally for agent experiments.

**Expectation check.** Intel UHD 630 is not a GPU you run inference on. This
will be CPU inference. With 16GB RAM, Gemma 2B and Llama 3.2 3B are
comfortable. 7B models work but feel sluggish. Anything bigger is not worth
it on this hardware.

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable --now ollama

# Pull a small model
ollama pull gemma2:2b
ollama run gemma2:2b
```

OpenClaw (or whichever agent runner you are using) should accept an Ollama
endpoint at `http://localhost:11434`. If you want the agent reachable from
the Mac too: `OLLAMA_HOST=0.0.0.0:11434` plus a firewall rule, reachable
over Tailscale.

If local LLM becomes a real priority later, the honest options are:

1. Shove a used Nvidia card into the OptiPlex. Check PSU headroom (the SFF
   ships with a 200W PSU, which constrains you to low-profile, low-TDP cards
   like a GTX 1650 or a T1000). Not a great upgrade path.
2. Build or buy a second box for inference. More money, but the 3070 stays
   as your workstation.
3. Stick with small models and treat this as experimentation, not production.

---

## 8. Config Gaps to Fill

Concrete list of files the current rice repo is missing but references.
Tackle during Phase 2.

- `hypr/hyprlock.conf`: lock screen. Minimal example: blur background, show
  clock, show user, password box.
- `hypr/hypridle.conf`: idle daemon. Triggers hyprlock after N minutes, turns
  the screen off after M minutes.
- `dunst/dunstrc`: notification styling to match the rice's color palette.
- `nvim/`: neovim starter. Recommend LazyVim as a turnkey starting point.
- (Optional) `wlogout/` or a shell script for a graphical power menu. Your
  rofi `powermenu.sh` already covers this, so skip unless you want a
  separate widget.
- (Optional) `systemd/user/`: any user services you write later.

---

## 9. Rollback and Recovery

Things that will eventually go wrong, and what you do about each.

| Symptom                                | First move                                                                 |
| -------------------------------------- | -------------------------------------------------------------------------- |
| Hyprland logs you straight back out    | At greeter, pick XFCE. Open a terminal. `git -C ~/Code/wheatstacks-rice log` and `git diff` to see the last change. Revert or fix. |
| Black screen at boot                   | Ctrl+Alt+F2 for a TTY. Log in, `journalctl -xb` to read errors.            |
| Broken package after update            | `sudo pacman -Syu` fixes most things. For the one-off: downgrade via `sudo downgrade <pkg>` (from AUR).                             |
| SDDM will not start                    | TTY in, `sudo systemctl status sddm`. Disable it and fall back to `startx`-equivalent or `Hyprland` invoked from TTY.               |
| Network dies                           | `nmcli device status` to diagnose. `sudo systemctl restart NetworkManager`.                                                         |
| Lost access to the OptiPlex remotely   | Walk to it. Keep a monitor and keyboard reachable for the first month.     |

Back up the dotfiles by using git. Back up your actual data (docs, vault) by
having Syncthing replicate to the Mac and ideally one more target (external
drive or a cloud provider).

---

## 10. First Week Checklist

Daily drivers for the first week to actually learn the system.

- [ ] Customize `hypr/user.conf` with any personal tweaks instead of editing
      the core configs. That file loads last and wins.
- [ ] Put a real wallpaper in `~/Pictures/Wallpapers/`.
- [ ] Adjust `monitor = , preferred, auto, 1` in `hyprland.conf` to match
      your actual display (resolution, refresh, position).
- [ ] Learn five vim motions a day. `:Tutor` in neovim walks you through it.
- [ ] Commit your tweaks daily. `gaa && gc "tweak: <what>" && gp`.
- [ ] When something confuses you, read `man <command>` before Googling. It
      rewires how you learn the system.

---

## 11. What This Plan Deliberately Does Not Include

To keep scope honest:

- **BTRFS + snapper.** Real rollback with filesystem snapshots is great, but
  it adds a layer of complexity you do not need on day one. Revisit in month
  two if you want automatic snapshot-based rollbacks.
- **Custom kernel.** Stock `linux` (or `linux-zen` if EndeavourOS defaults
  there) is fine. Do not tune what you have not measured.
- **NixOS.** Different religion. If you like the reproducibility ideas you
  will read about, note them and come back in six months.
- **Docker Swarm / k3s.** You do not have a homelab yet. Start with one
  service at a time. Docker Compose is enough for a long time.

---

## Appendix A: Quick Reference

**Keybinds that matter on day one** (from `keybinds.conf`):

| Keys                | Action                     |
| ------------------- | -------------------------- |
| Super+T             | Terminal (kitty)           |
| Super+B             | Browser (firefox)          |
| Super+E             | File manager (thunar)      |
| Super+D             | Rofi launcher              |
| Super+Q             | Close window               |
| Super+F             | Fullscreen                 |
| Super+1..9          | Workspace 1..9             |
| Super+Shift+1..9    | Move window to workspace N |
| Super+W             | Toggle browser drawer      |
| Super+N             | Toggle Obsidian drawer     |
| Super+`             | Toggle scratchpad          |
| Ctrl+Shift+Esc      | Toggle sysmon              |
| Super+Shift+V       | Clipboard history          |
| Super+Delete        | Lock screen                |
| Super+Shift+Delete  | Exit Hyprland              |
| Super+Shift+R       | Reload Hyprland config     |

**Pacman cheat sheet**:

```
sudo pacman -Syu           # update everything
sudo pacman -S <pkg>       # install
sudo pacman -R <pkg>       # remove
sudo pacman -Rns <pkg>     # remove with deps and config
pacman -Ss <query>         # search official repos
pacman -Qi <pkg>           # info on installed package
pacman -Qdt                # orphan packages
yay -S <pkg>               # install from AUR
yay -Syu                   # update AUR too
```
