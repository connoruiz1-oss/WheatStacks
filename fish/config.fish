# ╔══════════════════════════════════════════════════════════════╗
# ║  FISH SHELL CONFIG                                          ║
# ║                                                              ║
# ║  Fish is a modern shell that works well out of the box.      ║
# ║  This config adds: Starship prompt, useful aliases,          ║
# ║  git abbreviations, and optional tool integrations.          ║
# ║                                                              ║
# ║  Fish docs: https://fishshell.com/docs/current/              ║
# ╚══════════════════════════════════════════════════════════════╝

# --- Starship prompt ---
# Starship renders your prompt (the bit before your cursor).
# Its config lives at ~/.config/starship/starship.toml
starship init fish | source

# --- Optional tool integrations ---
# These only activate if the tool is installed. No errors if missing.

# zoxide: smart `cd` that learns your most-used directories.
# After installing, type `z project` instead of `cd ~/Code/project`.
if type -q zoxide
    zoxide init fish --cmd cd | source
end

# direnv: auto-loads .envrc files when you enter a directory.
# Useful for project-specific env vars.
if type -q direnv
    direnv hook fish | source
end

# --- Aliases ---
# eza is a modern replacement for `ls` with icons and colors.
# If you don't have eza installed, these will just fail silently.
if type -q eza
    alias ls  "eza --icons --group-directories-first -1"
    alias ll  "eza --icons --group-directories-first -la"
    alias la  "eza --icons --group-directories-first -a"
    alias lt  "eza --icons --group-directories-first -T --level=2"
end

# Shorthand for common tools
alias v    "nvim"
alias cls  "clear"
alias cat  "bat --style=plain"    # bat is a better cat (with syntax highlighting)
alias df   "df -h"                # human-readable disk space
alias du   "du -sh"               # human-readable directory size

# --- Git abbreviations ---
# Abbreviations expand when you press Space, so "gs<space>" becomes "git status ".
# This is better than aliases because you can see what actually runs.
abbr -a gs   "git status"
abbr -a ga   "git add"
abbr -a gaa  "git add ."
abbr -a gc   "git commit -m"
abbr -a gca  "git commit -am"
abbr -a gp   "git push"
abbr -a gpl  "git pull"
abbr -a gd   "git diff"
abbr -a gl   "git log --oneline --graph --decorate -20"
abbr -a gsw  "git switch"
abbr -a gb   "git branch"
abbr -a gco  "git checkout"
abbr -a gst  "git stash"
abbr -a gsp  "git stash pop"
abbr -a lg   "lazygit"

# --- Environment ---
set -gx EDITOR nvim
set -gx VISUAL nvim

# XDG directories (keeps your home directory clean)
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx XDG_STATE_HOME "$HOME/.local/state"

# --- User config hook ---
# Put personal tweaks in this file (it won't be overwritten by updates)
if test -f ~/.config/fish/user-config.fish
    source ~/.config/fish/user-config.fish
end
