#!/usr/bin/env bash

# Turn wifi off and on again to fix connectivity issues
nmcli radio wifi off
nmcli radio wifi on
