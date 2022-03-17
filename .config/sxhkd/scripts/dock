#!/bin/bash

NCMPCPP=""
TERMINAL=""
CODE="﬏"
DISCORD="碌"
TELEGRAM=""
THUNAR=""
FIREFOX=""

RES=`echo "$NCMPCPP|$TERMINAL|$CODE|$DISCORD|$THUNAR|$FIREFOX|$TELEGRAM" | rofi -dmenu -sep "|" -theme dock -monitor -1`

[[ $RES == $NCMPCPP ]] && urxvt -name "music_player" -e ncmpcpp_art
[[ $RES == $TERMINAL ]] && urxvt
[[ $RES == $CODE ]] && code
[[ $RES == $DISCORD ]] && discord
[[ $RES == $THUNAR ]] && thunar
[[ $RES == $FIREFOX ]] && firefox
[[ $RES == $TELEGRAM ]] && telegram-desktop