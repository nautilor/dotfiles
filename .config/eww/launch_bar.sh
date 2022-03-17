#!/bin/bash


function toggle() {
    eww $1 bar
}

WINDOWS=`eww windows | grep bar | grep "*"`
[ "$WINDOWS" = "" ] && toggle "open" || toggle "close"