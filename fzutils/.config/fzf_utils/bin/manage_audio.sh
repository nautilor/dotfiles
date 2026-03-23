#!/usr/bin/env bash

if ! command -v wiremix &> /dev/null
then
		echo "wiremix could not be found, please install it first"
		exit 1
fi

wiremix
