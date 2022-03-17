#!/bin/bash
WINDOW=`bspc query -N focused -n`
if [ ! "$WINDOW" == "" ]; then
    NAME=`xprop -id "$WINDOW" WM_CLASS | sed 's/.*=//g' | sed 's/,.*//g' | xargs 2>/dev/null`
else
    NAME="desktop"
fi

[ "$NAME" == "music_player" ] && echo "%{T7}阮 %{T-} Music" && exit 0
[ "$NAME" == "urxvt" ] && echo "%{T7} %{T-} Terminal" && exit 0
[ "$NAME" == "urxvt_center" ] && echo "%{T7} %{T-} Terminal" && exit 0
[ "$NAME" == "code" ] && echo "%{T7}﬏ %{T-} VS Code" && exit 0
[ "$NAME" == "chromium" ] && echo "%{T7} %{T-} Chromium" && exit 0
[ "$NAME" == "discord" ] && echo "%{T7}碌 %{T-} Discord" && exit 0
[ "$NAME" == "telegram-desktop" ] && echo "%{T7} %{T-} Telegram" && exit 0
[ "$NAME" == "kotatogram-desktop" ] && echo "%{T7} %{T-} Kotatogram" && exit 0
[ "$NAME" == "krita" ] && echo "%{T7} %{T-} Krita" && exit 0
[ "$NAME" == "sublime_merge" ] && echo "%{T7} %{T-} Sublime Merge" && exit 0
[ "$NAME" == "obs" ] && echo "%{T7} %{T-} OBS Studio" && exit 0
[ "$NAME" == "thunar" ] && echo "%{T7} %{T-} Thunar" && exit 0
[ "$NAME" == "GLava" ] && echo "%{T7} %{T-} Desktop" && exit 0
[ "$NAME" == "desktop" ] && echo "%{T7} %{T-} Desktop" && exit 0
[ "$NAME" == "Navigator" ] && echo "%{T7} %{T-} Firefox" && exit 0
[ "$NAME" == "gucharmap" ] && echo "%{T7} %{T-} CharMap" && exit 0
[ "$NAME" == "kitty" ] && echo "%{T7} %{T-} Kitty" && exit 0
echo "%{T7} %{T-}$NAME"
