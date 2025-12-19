#!/bin/bash

ACTIVE_WINDOW_CLASS=$(hyprctl -j activewindow | jq -r '.class')

if [[ "$ACTIVE_WINDOW_CLASS" == "obs" ]]; then
    echo "󰒃 OBS"
else
    echo ""
fi