#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  POWER MENU                                                 ║
# ║                                                              ║
# ║  Shows a rofi menu with power options.                       ║
# ║  Bound to a keybind in keybinds.conf.                        ║
# ╚══════════════════════════════════════════════════════════════╝

options=" Lock\n Suspend\n Logout\n Reboot\n Shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -p "Power" -theme ~/.config/rofi/config.rasi -lines 5)

case "$chosen" in
    " Lock")     hyprlock ;;
    " Suspend")  systemctl suspend ;;
    " Logout")   hyprctl dispatch exit ;;
    " Reboot")   systemctl reboot ;;
    " Shutdown") systemctl poweroff ;;
esac
