#!/bin/bash

function toggle() {
    eww $1 volume
    eww $1 poweroff
    eww $1 reboot
    eww $1 logout
    eww $1 lock
    eww $1 music
    eww $1 profile
    eww $1 time
    eww $1 date
}

WINDOWS=`eww windows | grep date | grep "*"`
[ "$WINDOWS" = "" ] && toggle "open" || toggle "close"