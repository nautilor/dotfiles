#!/bin/bash

LAYOUT=`bspc query -T -d | jq -r .layout`

# (box :orientation \"v\" :class \"layout-tiled\" :halign \"center\" :valign \"center\" :vexpand true :hexpand true \"\")
[ "$LAYOUT" = "tiled" ] && echo "(box :orientation \"v\" :class \"layout-tiled\" :halign \"center\" :valign \"center\" :vexpand true :hexpand true \"\")" && exit
[ "$LAYOUT" = "monocle" ] && echo "(box :orientation \"v\" :class \"layout-monocle\" :halign \"center\" :valign \"center\" :vexpand true :hexpand true \"\")" && exit