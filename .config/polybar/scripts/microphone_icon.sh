#!/bin/bash

DEFAULT=`pactl get-default-source`
STATUS=`pactl get-source-mute $DEFAULT | sed 's/.*:\s//g'`
#   
[ "$STATUS" == "no" ] && echo "%{T7}%{F#A3BE8C}%{F-}%{T-}" || echo "%{T7}%{F#A3BE8C}%{F-}%{T-}"