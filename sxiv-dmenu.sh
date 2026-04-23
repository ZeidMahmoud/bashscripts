#!/bin/sh
files=$(cat)
[ -z "$files" ] && exit 1

browse_dirs() {
    show_hidden="no"
    current="$HOME"
    while true; do
        if [ "$show_hidden" = "yes" ]; then
            entries=$(find "$current" -mindepth 1 -maxdepth 1 -type d | sort | xargs -I{} basename {})
            toggle_opt="[ hide dotfiles ]"
        else
            entries=$(find "$current" -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort | xargs -I{} basename {})
            toggle_opt="[ show dotfiles ]"
        fi
        menu=$(printf '%s\n%s\n%s\n%s\n' \
            "[ select: $current ]" \
            "$toggle_opt" \
            "[ .. go up ]" \
            "$entries")
        chosen=$(printf '%s' "$menu" | dmenu -i -l 15 -p "$current")
        [ -z "$chosen" ] && return 1
        case "$chosen" in
            "[ select: $current ]") echo "$current"; return 0 ;;
            "[ show dotfiles ]")    show_hidden="yes" ;;
            "[ hide dotfiles ]")    show_hidden="no" ;;
            "[ .. go up ]")         current=$(dirname "$current") ;;
            *)                      current="$current/$chosen" ;;
        esac
    done
}

case "$1" in
    "c")
        dest=$(browse_dirs)
        [ -z "$dest" ] && exit 1
        mkdir -p "$dest"
        echo "$files" | tr '\n' '\0' | xargs -0 cp -it "$dest" --
        ;;
    "m")
        dest=$(browse_dirs)
        [ -z "$dest" ] && exit 1
        mkdir -p "$dest"
        echo "$files" | tr '\n' '\0' | xargs -0 mv -it "$dest" --
        ;;
    "d")
        confirm=$(printf "No\nYes" | dmenu -p "Delete selected files?")
        [ "$confirm" = "Yes" ] || exit 1
        echo "$files" | tr '\n' '\0' | xargs -0 rm --
        ;;
esac
