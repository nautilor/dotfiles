#!/bin/bash

STATE=`xset q | grep Caps | awk '{ print $4 }'`

[ "$STATE" = "off" ] && echo  || echo 