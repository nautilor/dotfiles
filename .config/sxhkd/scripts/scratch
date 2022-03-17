#!/usr/bin/env sh

SCRATCH="$HOME/.scratch"

function help {
    echo -e "USAGE\n=====\n- $0"
    echo -e "  - push > add window to stack"
    echo -e "  - pop  > remove window to stack"
    exit
}

function push {
    WID=`xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | awk '{print $2}'`
    xdo hide $WID
    echo "$WID" >> $SCRATCH
    exit
}

function pop {
    WID=`head -n 1 $SCRATCH`
    [ $(cat $SCRATCH | wc -l) -eq 1 ] && rm $SCRATCH || grep -v $WID $SCRATCH > .temp && mv .temp $SCRATCH
    xdo show $WID
    exit
}

[ $# -eq 0 ] && help
[ "$1" = "pop" ] && pop
[ "$1" = "push" ] && push
