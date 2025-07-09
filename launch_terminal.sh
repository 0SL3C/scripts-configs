#!/bin/bash

# Get the focused window's PID
parent_pid=$(hyprctl activewindow -j | jq -r '.pid')

# Find the first child process that's your shell (zsh)
shell_pid=$(pgrep -P $parent_pid zsh | head -n 1)

# Fallback to parent if no child shell found
[ -z "$shell_pid" ] && shell_pid=$parent_pid

# Get cwd of the shell or terminal
cwd=$(readlink "/proc/$shell_pid/cwd")

# Fallback if invalid
[ -d "$cwd" ] || cwd="$HOME"

# Check if alacritty exists
if command -v alacritty >/dev/null 2>&1; then
    alacritty --working-directory "$cwd"
else
    notify-send "Error" "alacritty not found in PATH."
    echo "Error: alacritty not found in PATH." >&2
fi