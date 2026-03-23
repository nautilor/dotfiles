#!/usr/bin/env bash
hyprctl keyword animations:enabled false
DXVK_FILTER_DEVICE_NAME="NVIDIA" hyprshot --freeze -m region --raw | satty --filename -
hyprctl keyword animations:enabled true
