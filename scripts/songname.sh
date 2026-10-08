#!/bin/bash

# --------------------------------------------------
# Variables
# --------------------------------------------------

title=""
status=""

player_status=""
player_url=""
album=""


# --------------------------------------------------
# playerctl
# --------------------------------------------------

player_status=$(playerctl --player="$PLAYER" status 2>/dev/null |
    tr -d '\n')

if [ -n "$player_status" ]; then

    album=$(playerctl --player="$PLAYER" metadata \
        --format '{{xesam:album}}' 2>/dev/null |
        tr -d '\n')

    player_url=$(playerctl --player="$PLAYER" metadata \
        --format '{{xesam:url}}' 2>/dev/null |
        tr -d '\n')

fi


# --------------------------------------------------
# Ordinary YouTube
# --------------------------------------------------
#
# Якщо відкрито youtube.com/watch або youtu.be:
# нічого не показуємо і НЕ переходимо до cliamp.
#
# Це прибирає старий трек cliamp з Waybar,
# коли ти наводишся на YouTube.
# --------------------------------------------------

case "$player_url" in
    *youtube.com/watch*|\
    *www.youtube.com/watch*|\
    *youtu.be/*)

        # Якщо це YouTube Music і є album —
        # не виходимо, бо його потрібно показувати.
        if [ -z "$album" ]; then
            exit 0
        fi

        ;;
esac


# --------------------------------------------------
# YouTube Music
# --------------------------------------------------

if [ -n "$album" ]; then

    title=$(playerctl --player="$PLAYER" metadata \
        --format '{{artist}} - {{title}}' 2>/dev/null |
        sed -e 's/ - YouTube Music//' \
            -e 's/ - YouTube//' |
        tr -d '\n')

    status="$player_status"

fi


# --------------------------------------------------
# cliamp
# --------------------------------------------------

if [ -z "$title" ]; then

    json=$(cliamp status --json 2>/dev/null)

    if printf '%s' "$json" | jq -e . >/dev/null 2>&1; then

        status=$(printf '%s' "$json" |
            jq -r '.state // empty')

        song=$(printf '%s' "$json" |
            jq -r '.track.title // empty')

        artist=$(printf '%s' "$json" |
            jq -r '.track.artist // empty')

        path=$(printf '%s' "$json" |
            jq -r '.track.path // empty')

        station=$(printf '%s' "$json" |
            jq -r '.track.station // empty')

    else
        exit 0
    fi


    # --------------------------------------------------
    # cliamp Radio
    # --------------------------------------------------
    #
    # Radio визначаємо ТІЛЬКИ по path:
    #
    # https://radio.cliamp.stream/...
    #
    # Бо station у звичайних треках може бути
    # неактуальним / стороннім значенням.
    # --------------------------------------------------

    if [[ "$path" == https://radio.cliamp.stream/* ]]; then

        cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
        cache_file="$cache_dir/songname-cliamp-radio-station"

        mkdir -p "$cache_dir"

        old_station=""

        if [ -f "$cache_file" ]; then
            old_station=$(cat "$cache_file")
        fi


        # Нова станція -> показуємо її один цикл
        if [ -n "$station" ] && [ "$station" != "$old_station" ]; then

            title="$station"

            printf '%s' "$station" > "$cache_file"


        # Вже знайома станція -> показуємо трек
        elif [ -n "$song" ]; then

            if [ -n "$artist" ]; then
                title="$artist - $song"
            else
                title="$song"
            fi

        fi


    # --------------------------------------------------
    # cliamp SoundCloud / інші треки
    # --------------------------------------------------

    else

        if [ -n "$song" ]; then

            if [ -n "$artist" ]; then
                title="$artist - $song"
            else
                title="$song"
            fi

        fi

    fi


    # --------------------------------------------------
    # cliamp state -> Waybar
    # --------------------------------------------------

    case "$status" in
        playing)
            status="Playing"
            ;;
        paused)
            status="Paused"
            ;;
        stopped)
            status="Stopped"
            ;;
    esac

fi


# --------------------------------------------------
# Nothing to display
# --------------------------------------------------

if [ -z "$title" ]; then
    exit 0
fi


# --------------------------------------------------
# Escape Pango / Waybar
# --------------------------------------------------

title=$(printf '%s' "$title" |
    sed -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' |
    tr -d '\n')


# --------------------------------------------------
# Waybar JSON
# --------------------------------------------------

if [ "$1" = "-json" ]; then

    printf '{"alt":"%s","tooltip":"%s","text":"%s"}\n' \
        "$status" \
        "$title" \
        "$title"

else

    printf '%s\n' "$title"

fi





# PLAYER="chromium"

# # --------------------------------------------------
# # YouTube Music
# # --------------------------------------------------
# album=$(playerctl --player="$PLAYER" metadata \
#     --format '{{xesam:album}}' 2>/dev/null | tr -d '\n')

# if [ -n "$album" ]; then

#     title=$(playerctl --player="$PLAYER" metadata \
#         --format '{{artist}} - {{title}}' 2>/dev/null |
#         sed -e 's/ - YouTube Music//' \
#             -e 's/ - YouTube //' |
#         tr -d '\n')

#     status=$(playerctl --player="$PLAYER" status 2>/dev/null | tr -d '\n')

# else

#     title=""

# fi



# title=$(playerctl --player="$PLAYER" metadata \
#     --format '{{artist}} - {{title}}' 2>/dev/null |
#     sed -e 's/ - YouTube Music//' \
#         -e 's/ - YouTube//' |
#     tr -d '\n')

# status=$(playerctl --player="$PLAYER" status 2>/dev/null | tr -d '\n')


# # --------------------------------------------------
# # cliamp
# # --------------------------------------------------

# if [ -z "$title" ]; then

#     json=$(cliamp status --json 2>/dev/null)

#     # state
#     status=$(printf '%s\n' "$json" |
#         sed -n 's/^[[:space:]]*"state":[[:space:]]*"\([^"]*\)".*/\1/p' |
#         head -n 1)

#     # track.title
#     song=$(printf '%s\n' "$json" |
#         sed -n '/"track"[[:space:]]*:/,/^[[:space:]]*}/{
#             s/^[[:space:]]*"title":[[:space:]]*"\(.*\)",\{0,1\}/\1/p
#         }' |
#         head -n 1)

#     # track.artist
#     artist=$(printf '%s\n' "$json" |
#         sed -n '/"track"[[:space:]]*:/,/^[[:space:]]*}/{
#             s/^[[:space:]]*"artist":[[:space:]]*"\(.*\)",\{0,1\}/\1/p
#         }' |
#         head -n 1)


#     # JSON unicode escape -> normal character
#     song=$(printf '%s' "$song" |
#         sed 's/\\u0026/\&/g')

#     artist=$(printf '%s' "$artist" |
#         sed 's/\\u0026/\&/g')


#     # Якщо artist є:
#     # Artist - Title
#     #
#     # Якщо artist немає:
#     # просто Title

#     if [ -n "$song" ]; then
#         if [ -n "$artist" ]; then
#             title="$artist - $song"
#         else
#             title="$song"
#         fi
#     fi


#     # cliamp state -> Waybar state

#     if [ "$status" = "playing" ]; then
#         status="Playing"
#     elif [ "$status" = "paused" ]; then
#         status="Paused"
#     fi

# fi


# # --------------------------------------------------
# # Escape для Pango / Waybar
# # --------------------------------------------------

# if [ -n "$title" ]; then

#     # Спочатку &, щоб не створювати подвійне escaping
#     title=$(printf '%s' "$title" |
#         sed -e 's/&/\&amp;/g' \
#             -e 's/</\&lt;/g' \
#             -e 's/>/\&gt;/g' \
#             -e 's/"/\&quot;/g' |
#         tr -d '\n')


#     # JSON для Waybar

#     if [ "$1" = "-json" ]; then
#         printf '{"alt":"%s","tooltip":"%s","text":"%s"}\n' \
#             "$status" "$title" "$title"
#     else
#         printf '%s\n' "$title"
#     fi

# fi
