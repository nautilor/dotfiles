#!/bin/bash

[[ "`mpc | wc -l`" == "3" ]] && echo " `mpc 2>/dev/null | head -n1` " || echo " No Music Playing " && exit