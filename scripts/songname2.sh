PLAYER="chromium"

# YouTube Music
title=$(playerctl --player="$PLAYER" metadata --format '{{artist}} - {{title}}' 2>/dev/null |
    sed -e 's/ - YouTube Music//; s/ - YouTube//' |
    tr -d '\n')

status=$(playerctl --player="$PLAYER" status 2>/dev/null | tr -d '\n')


# cliamp
if [ -z "$title" ]; then

    cliamp_json=$(cliamp status --json 2>/dev/null)

    status=$(printf '%s\n' "$cliamp_json" |
        sed -n 's/.*"state":[[:space:]]*"\([^"]*\)".*/\1/p' |
        head -1)

    song=$(printf '%s\n' "$cliamp_json" |
        awk '
            /"track"[[:space:]]*:/ { track=1 }
            track && /"title"[[:space:]]*:/ {
                match($0, /"title"[[:space:]]*:[[:space:]]*"([^"]*)"/, a)
                print a[1]
                exit
            }
        ')

    artist=$(printf '%s\n' "$cliamp_json" |
        awk '
            /"track"[[:space:]]*:/ { track=1 }
            track && /"artist"[[:space:]]*:/ {
                match($0, /"artist"[[:space:]]*:[[:space:]]*"([^"]*)"/, a)
                print a[1]
                exit
            }
        ')

    if [ -n "$song" ]; then
        if [ -n "$artist" ]; then
            title="$artist - $song"
        else
            title="$song"
        fi
    fi

    if [ "$status" = "playing" ]; then
        status="Playing"
    elif [ "$status" = "paused" ]; then
        status="Paused"
    fi

fi


# Pango markup escape
title=$(printf '%s' "$title" |
    sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' |
    tr -d '\n')


# Waybar JSON
if [ -n "$title" ]; then

    if [ "$1" = "-json" ]; then
        printf '{"alt":"%s","tooltip":"%s","text":"%s"}\n' \
            "$status" "$title" "$title"
    else
        echo "$title"
    fi

fi




# PLAYER="chromium"

# # YouTube Music
# title=$(playerctl --player="$PLAYER" metadata --format '{{artist}} - {{title}}' 2>/dev/null | sed -e 's/ - YouTube Music//; s/ - YouTube//' | tr -d '\n')
# status=$(playerctl --player="$PLAYER" status 2>/dev/null | tr -d '\n')

# # Якщо YouTube Music неактивний — беремо cliamp
# if [ -z "$title" ]; then
#     cliamp_status=$(cliamp status --json 2>/dev/null)

#     status=$(printf '%s\n' "$cliamp_status" | grep '"state"' | head -1 | sed 's/.*"state": *"\([^"]*\)".*/\1/')
#     artist=$(printf '%s\n' "$cliamp_status" | grep '"artist"' | head -1 | sed 's/.*"artist": *"\([^"]*\)".*/\1/')
#     title=$(printf '%s\n' "$cliamp_status" | grep '"title"' | head -1 | sed 's/.*"title": *"\([^"]*\)".*/\1/')

#     if [ -n "$artist" ]; then
#         title="$artist - $title"
#     fi

#     [ "$status" = "playing" ] && status="Playing"
#     [ "$status" = "paused" ] && status="Paused"
# fi

# # Waybar JSON
# if [ -n "$title" ]; then
#     title=$(printf '%s' "$title" | sed 's/&/\&amp;/g; s/"/\\"/g' | tr -d '\n')

#     if [ "$1" = "-json" ]; then
#         printf '{"alt":"%s","tooltip":"%s","text":"%s"}\n' "$status" "$title" "$title"
#     else
#         echo "$title"
#     fi
# fi


# PLAYER="chromium"
# CLIAMP_PLAYER="cliamp"
# title=$(playerctl --player=$PLAYER metadata --format '{{artist}} - {{title}}' | sed -e 's/ - YouTube Music//; s/ - YouTube//; s/&/\&amp;/g; s/"/\\\"/g' | tr -d '\n')
# status=$(playerctl --player=$PLAYER status | tr -d '\n')

# if [ ! -z "$title" ]; then
#   if [[ "$1" == "-json" ]]; then
#     echo "{\"alt\": \"$status\", \"tooltip\": \"$title\", \"text\": \"$title\"}"
#   else
#     icon="󰏤"
#     if [[ $status == Playing ]]; then icon=" "; fi
#     echo "$icon $title"
#   fi
# fi
