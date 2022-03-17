#!/bin/bash

[[ `mpc status | grep paused` ]] && echo "喇" && exit || echo "" && exit