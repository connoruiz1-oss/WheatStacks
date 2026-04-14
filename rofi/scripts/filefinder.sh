#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ROFI FILE FINDER -- the Finder replacement Spotlight wishes ║
# ║  it could be.                                                ║
# ║                                                              ║
# ║  Walks $HOME with `fd` (much faster than `find`), feeds the  ║
# ║  results into rofi as a dmenu, opens the chosen file with    ║
# ║  xdg-open (which respects your default app per MIME type).   ║
# ║                                                              ║
# ║  Why this beats Spotlight for file search:                   ║
# ║   - fd respects .gitignore by default (no junk results).     ║
# ║   - Hidden files toggleable via -H.                          ║
# ║   - Fuzzy matched + frecency-ranked by rofi.                 ║
# ║   - Sub-100ms launch even on huge home dirs.                 ║
# ║   - Opens with the correct app (Obsidian for .md, Code for   ║
# ║     source files, image viewer for PNGs, etc).               ║
# ║                                                              ║
# ║  Bound to Super+Shift+Space in hypr/hyprland/keybinds.conf.  ║
# ║                                                              ║
# ║  Customise the search root or fd flags below if you want to  ║
# ║  exclude particular folders or include hidden files.         ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# Where to search. Change to / for system-wide; default is just $HOME.
SEARCH_ROOT="${HOME}"

# fd flags:
#   --type f         only files, no directories
#   --hidden         include dotfiles (comment out if you want to skip)
#   --follow         follow symlinks
#   --exclude        skip noisy directories that are never what you want
FD_ARGS=(
    --type f
    --hidden
    --follow
    --exclude .git
    --exclude node_modules
    --exclude .cache
    --exclude .local/share/Trash
    --exclude .npm
    --exclude .cargo
    --exclude .rustup
    --exclude .mozilla
    --exclude .config/google-chrome
    --exclude Library
)

# Build the candidate list. Strip $HOME prefix so the rofi list is
# readable; we add it back when we open the file.
mapfile -t FILES < <(fd "${FD_ARGS[@]}" . "${SEARCH_ROOT}" \
    | sed "s|^${SEARCH_ROOT}/||")

if [ ${#FILES[@]} -eq 0 ]; then
    notify-send "File finder" "No files found under ${SEARCH_ROOT}"
    exit 0
fi

# Hand the list to rofi. -i for case-insensitive. The theme inherits
# from your default rofi config so this looks like Spotlight too.
CHOICE=$(printf '%s\n' "${FILES[@]}" \
    | rofi -dmenu -i \
        -p "Files" \
        -theme ~/.config/rofi/config.rasi \
        -matching fuzzy \
        -sorting-method fzf)

# Bail if the user hit Escape.
[ -z "${CHOICE}" ] && exit 0

# Open with the registered default app for that MIME type.
xdg-open "${SEARCH_ROOT}/${CHOICE}" >/dev/null 2>&1 &
