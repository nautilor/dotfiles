#!/usr/bin/env bash
#
# Shorten a piped path to its last two components, prefixed with "/…/",
# if it's longer than 3 slash-separated segments.
#
set -euo pipefail

awk -F '/' '{
	if (NF > 3) {
		print "/…/" $(NF - 1) "/" $NF
	} else {
		print
	}
}' < /dev/stdin
