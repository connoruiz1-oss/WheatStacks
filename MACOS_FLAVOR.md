# macOS-flavored layer

A summary of the macOS-inspired changes layered on top of the base
wheatstacks rice. Everything here is structural homage, not visual
mimicry: the wheatstacks (Monet) palette is preserved, but the layout
primitives (menubar, launcher, notifications, animation pacing) borrow
from macOS so the system feels familiar at a glance without giving up
its own identity.

## Guiding principles

1. **Speed over theatrics.** macOS animations are smooth but slow. We
   keep the *visual* pacing of macOS (no abrupt pops) but every
   animation is under 100ms. If you can perceive the animation as a
   distinct event, it is too long.
2. **Wheatstacks palette stays.** No Apple blue, no neutral grays. The
   russet accent and warm cream foreground continue to do the heavy
   lifting. Only layout, opacity, and shape were touched.
3. **Improve where macOS is weakest.** Spotlight's file search is the
   classic example. Our rofi-backed launcher beats it on raw speed,
   ranking, and extensibility (see §Spotlight below).
4. **Reversible.** Every change is in its own file with comments
   explaining the rationale, so you can revert any single piece.

---

## Files changed and why

### `hypr/hyprland/animations.conf` (rewritten)

Single ease-out curve, no spring, no overshoot. All animations 100ms
except workspace switch (200ms for visual continuity since the whole
screen moves). `borderangle` disabled outright since it constantly
redraws for no interaction value.

> Tuning: drop every speed value to `0` for fully instant motion, or
> set `enabled = false` to kill animations entirely.

### `hypr/hyprland/decoration.conf`

Rounded corners 10 → 8 (closer to actual macOS window radius). Active
opacity 0.95 → 0.98 and inactive 0.90 → 0.94 because macOS windows are
basically opaque. Blur strengthened slightly (size 6 → 8, passes 2 → 3,
vibrancy added) to read as macOS "vibrancy" on the menubar and rofi.
Shadow widened and softened (range 15 → 28, render_power 3 → 2, slight
downward offset) for the diffuse macOS shadow look.

### `hypr/hyprland/general.conf`

Border 2px → 1px. Gaps tightened (in 5 → 4, out 10 → 8). macOS does
not tile, but its window spacing reads tight rather than airy.

### `hypr/hyprland/rules.conf`

Added `layerrule = blur, notifications` so dunst toasts get the
frosted-glass background, matching the macOS Notification Center look.

### `hypr/hyprland/keybinds.conf`

New launcher keybinds:
- `Super+Space` → unified search (combi mode: apps + windows + ssh).
  Mirrors `Cmd+Space` on macOS for muscle memory.
- `Super+D` → apps-only launcher (preserved from the original config).
- `Super+Shift+Space` → fd-backed file finder script. This is the
  Finder/Spotlight replacement.

### `waybar/config.jsonc`

Layout rebuilt as a menubar:
- Height 36 → 28 (macOS menubar is ~24-28px).
- Margins zeroed so the bar runs flush with the screen edges.
- `hyprland/window` module added on the left, so the focused window
  title acts like the macOS app-name menu slot.
- Clock format updated to macOS style (`Mon Apr 13  2:45 PM`).
- Title rewrite rules clean up Firefox / Obsidian / Code titles.

### `waybar/style.css`

- No corner rounding (flush to edge).
- Hairline 1px bottom border instead of an outline.
- Background opacity 0.85 → 0.55 with stronger blur from Hyprland.
- Font switched to Inter (closest free analogue to SF Pro), with
  JetBrains Mono Nerd Font kept as fallback for icons.
- Module padding tightened.
- Workspace pills smaller and more subdued.

### `rofi/config.rasi` (rewritten)

Spotlight-shaped *and* meaningfully better. The aesthetic changes:
- 580px wide, centered, anchored 200px above screen center (matches
  Spotlight's resting position, not dead-center).
- Single column results.
- Tall search input with large font and a hairline divider.
- Inter font, no border, just a soft shadow from the layer blur.

The behavioural improvements over Spotlight (see §Spotlight):
- True fuzzy matching (`matching = fuzzy`).
- fzf-style sorting (`sorting-method = fzf`).
- Frecency: results you pick often bubble up.
- Combined modes in one input (apps, windows, ssh, files, run).
- Mode cycling inside the launcher (`Ctrl+Tab`).
- Parses `~/.ssh/config` and `known_hosts` for instant SSH search.

### `rofi/scripts/filefinder.sh` (new)

`fd`-backed file picker. fd is fast (parallel walk, respects
`.gitignore`), excludes the noisy directories Spotlight insists on
indexing (caches, node_modules, browser profiles), and opens results
with `xdg-open` so each file lands in its preferred app (Obsidian for
markdown, Code for source files, image viewer for PNGs).

Hold the tradeoff in mind: this only searches filenames, not file
*contents*. Spotlight does content indexing. If you need full-text
search across notes, that is a separate problem (Obsidian's own
search inside the vault, or `ripgrep` over a documents folder via a
similar custom rofi script).

### `dunst/dunstrc` (new)

macOS-style top-right notifications: anchored top-right with a 12x40
offset (clears the menubar plus a small gap), 360px wide, 10px corner
radius, hairline border, 6px gap between stacked toasts, max 5 visible
at once. Frame color matches the wheatstacks `bg-overlay`. Critical
notifications (`urgency_critical`) get a red frame and never time out.

### `kitty/kitty.conf`

Padding 10 → 8 for tighter window content. Opacity 0.92 → 0.96 (macOS
Terminal feels nearly opaque). `hide_window_decorations yes` so the
kitty title bar is gone, since the Hyprland border + waybar window
title module already say what's open.

### `install.sh`

Added `link_config "dunst" "dunst"` so the new dunst directory is
symlinked into `~/.config/dunst` on install.

---

## Spotlight: why our launcher actually wins

Spotlight has a few real strengths (system-wide indexing, calculator
inline, unit conversion) and one big weakness: file search ranking is
mediocre and it is slow to launch a freshly-typed query because of
indexing daemon overhead.

Our rofi setup gives you:

| Feature                    | Spotlight              | Rofi (this config)                              |
| -------------------------- | ---------------------- | ----------------------------------------------- |
| Launch time                | 100-300ms (daemon)     | <50ms (cold start)                              |
| Fuzzy match                | Substring + metadata   | True fuzzy with fzf-style ranking               |
| Frecency                   | Limited                | Yes, learns your top picks per mode             |
| Search scope               | Files + apps + web     | Apps + windows + ssh + files + run + custom     |
| Mode switching mid-query   | No                     | Yes (`Ctrl+Tab`)                                |
| Customisable               | Barely                 | Arbitrary scripts via dmenu                     |
| File excludes              | System-defined         | Yours, in `filefinder.sh`                       |
| Open with right app        | Yes                    | Yes (via `xdg-open`)                            |

**What Spotlight still wins:** built-in calculator and unit conversion
inline in the search results, system-wide content search (PDF text,
email bodies). For calculator/units, `qalc` (qalculate) is the answer:
add `bind = $mod SHIFT, Q, exec, kitty -e qalc` or wrap it in another
rofi script. For content search inside notes, do it inside Obsidian
where you already have full-text + tag + dataview search.

---

## Optional further moves (not yet applied)

Things you might want later, deliberately not done now to keep scope
honest:

1. **Apple-key ↔ Super swap.** If your keyboard has a Cmd-style
   modifier in Super's position you can leave it. If not, you can
   remap with `evremap` or Hyprland's `bind` to make the pinky reach
   feel right.
2. **Cursor theme.** macOS uses the Aqua cursor. Closest free analogue
   is the `BreezeX-RosePine-Linux` or `Capitaine` cursors. Install,
   then update `XCURSOR_THEME` in `hypr/hyprland/env.conf`.
3. **Inter font.** The waybar and rofi configs reference Inter. Install
   with `sudo pacman -S inter-font` (or `ttf-inter` on AUR) so the
   fallback to JetBrains Mono is not triggered.
4. **A real dock** (deferred per your request). When you want one,
   `nwg-dock-hyprland` is the cleanest option; we can add it without
   touching anything else.
5. **Calculator/unit rofi mode.** A `~/.config/rofi/scripts/qalc.sh`
   wrapper that pipes user input through `qalc` and shows results
   inline. Recreates Spotlight's strongest unique feature.

---

## Reverting any single change

Every changed file is a single concern. To revert just one:

```bash
cd ~/Code/wheatstacks-rice
git log --oneline -- hypr/hyprland/animations.conf   # find the macOS-flavor commit
git checkout <commit>^ -- hypr/hyprland/animations.conf
```

Or simply edit the file: every macOS-flavored value has an inline
comment explaining what the original setting was and why it changed.
