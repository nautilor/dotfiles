#!/bin/bash

DEFAULT=`pactl get-default-source`
STATUS=`pactl get-source-mute $DEFAULT | sed 's/.*:\s//g'`
[ "$STATUS" == "no" ] && echo "" || echo ""