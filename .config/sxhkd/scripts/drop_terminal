#!/usr/bin/env sh

SCRATCH="$HOME/.drop_terminal"

function help {
    echo -e "USAGE\n=====\n- $0"
    echo -e "  - show    > show the dropdown terminal"
    echo -e "  - hide    > hide the dropdown terminal"
    echo -e "  - toggle  > toggle the view of the dropdown terminal"
    exit
}

# check if the dropdown terminal is already open
function is_running {
    WID=`wmctrl -lx | grep "drop_terminal.drop_terminal" | grep -v "grep" | awk '{print $1}'`
    [ -z "$WID" ] && echo 1 || echo 0
}

# spawn a new one if needeed
function spawn {
    kitty --class drop_terminal &
    sleep 0.5
    WID=`wmctrl -lx | grep "drop_terminal.drop_terminal" | grep -v "grep" | awk '{print $1}'`
    echo "$WID" > $SCRATCH
}

# hide the dropdown terminal
function hide {
    WID=`wmctrl -lx | grep "drop_terminal.drop_terminal" | grep -v "grep" | awk '{print $1}'`   
    xdo hide $WID
    echo "$WID" > $SCRATCH
    exit
}

# show the dropdown terminal
function show {
    WID=`head -n 1 $SCRATCH 2>/dev/null`
    if [ `is_running` -eq 0 ]; then
        exit
    fi
    if [ -z "$WID" ]; then
        spawn &
        exit
    fi
    xdo show $WID
    exit
}

function toggle {
    if [ `is_running` -eq 0 ]; then
        hide
    else
        show
    fi
}

[ $# -eq 0 ] && help
[ "$1" = "hide" ] && hide
[ "$1" = "show" ] && show
[ "$1" = "toggle" ] && toggle

