#!/usr/bin/env bash

awk -F '/' '{if(NF > 3){print "/…/"$(NF-1)"/"$(NF)}else{print}}' < /dev/stdin
