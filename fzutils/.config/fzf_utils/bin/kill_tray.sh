#!/usr/bin/env bash


options=(
	"Steam"
	"Telegram"
	"WhatsApp"
	"All"
)

selected=$(printf '%s\n' "${options[@]}" | $FZF_COMMAND)

case $selected in
	"Steam")
		pkill -9 steam
		;;
	"Telegram")
		pkill -9 Telegram
		;;
	"WhatsApp")
		pkill -9 zapzap
		;;
	"All")
		pkill -9 steam
		pkill -9 Telegram
		pkill -9 zapzap
		;;
esac

