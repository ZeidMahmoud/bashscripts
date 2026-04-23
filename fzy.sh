#!/bin/bash

query=$(echo "" | fzy -p "🔍 Search: ") || exit 1

if [ -f "$query" ]; then
    xdg-open "$query"
elif pgrep -x "$query" >/dev/null; then
    killall "$query"
else
    echo "$query" | xclip -selection clipboard
    notify-send "Copied to clipboard: $query"
fi
