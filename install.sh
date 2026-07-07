#!/usr/bin/env bash

for item in `ls`; do
	if [ -d "$item" ]; then
		echo "Stowing $item"
		stow $item
	fi
done
	
