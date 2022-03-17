#!/bin/bash

LAYOUT=`bspc query -T -d | jq -r .layout`

# %{T7}%{F#54749A}%{F-}%{T-}
[ "$LAYOUT" = "tiled" ] && echo "%{T7}%{F#EBCB8B}%{F-}%{T-}  %{T7}%{F#434C5E}╏%{F-}%{T-}" && exit
[ "$LAYOUT" = "monocle" ] && echo "%{T7}%{F#A3BE8C}%{F-}%{T-}  %{T7}%{F#434C5E}╏%{F-}%{T-}" && exit