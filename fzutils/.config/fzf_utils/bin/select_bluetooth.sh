#!/usr/bin/env bash

if ! command -v bluetui &> /dev/null
then
		echo "bluetui could not be found, please install it first"
		exit 1
fi

bluetui
