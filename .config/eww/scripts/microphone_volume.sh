#!/bin/bash

if [ ! -z "`amixer -D pulse get Capture | grep Mono`" ]; then
    echo `amixer -D pulse get Capture | grep 'Mono:' | awk '{ print $4 }' | sed -E 's/\[|\]|%//g'`
else
    echo 0
fi