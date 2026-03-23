#!/usr/bin/env bash

if ! command -v nmtui &> /dev/null
then
		echo "nmtui could not be found. Please install it first."
		exit 1
fi

nmtui
