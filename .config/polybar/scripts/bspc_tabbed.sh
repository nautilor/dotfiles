#!/bin/bash

# CUSTOMIZATION
FONT="7"
SEP_COLOR="#434C5E"
SEP="%{T$FONT}%{F$SEP_COLOR}╏%{F-}%{T-}  "
TABBED="#B48EAD"
NO_TABBED="#A3BE8C"
ICON=""
# CUSTOMIZATION

WINID=$(xdotool getactivewindow 2>/dev/null)
if [ -z "$WINID" ]; then
    echo "${SEP}%{T$FONT}%{F$NO_TABBED}$ICON%{F-}%{T-}"
    exit
fi
WINCLASS=$(xprop -id "$WINID" | grep WM_CLASS)
[[ "$WINCLASS" =~ "tabbed" ]] && echo "${SEP}%{T$FONT}%{F$TABBED}$ICON%{F-}%{T-}" || echo "${SEP}%{T$FONT}%{F$NO_TABBED}$ICON%{F-}%{T-}"