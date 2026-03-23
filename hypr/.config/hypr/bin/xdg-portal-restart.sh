#!/usr/bin/env bash
killall -e xdg-desktop-portal-hyprland
killall xdg-desktop-portal
/usr/lib/xdg-desktop-portal-hyprland &
sleep 0.5
/usr/lib/xdg-desktop-portal &
