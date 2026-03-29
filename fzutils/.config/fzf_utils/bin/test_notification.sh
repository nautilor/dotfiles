#!/usr/bin/env bash

OPTIONS=("Normal" "Critical" "Normal with actions" "Critical with actions")
SELECTED=$(printf '%s\n' "${OPTIONS[@]}" | fzf --prompt="Select notification type: " --border)

case $SELECTED in
		"Normal")
				notify-send 'Adam Jefferson' 'Hey, How are you?' -i /usr/share/icons/Tela-circle-dracula/scalable/apps/telegram.svg
				;;
		"Critical")
				notify-send 'Adam Jefferson' 'Hey, How are you?' -i /usr/share/icons/Tela-circle-dracula/scalable/apps/telegram.svg -u 'critical'
				;;
		"Normal with actions")
				bash -c "notify-send 'Adam Jefferson' 'Hey, How are you?' -i /usr/share/icons/Tela-circle-dracula/scalable/apps/telegram.svg --action 'reply=Reply' --action 'ignore=Ignore'"
				;;
		"Critical with actions")
				bash -c "notify-send 'Adam Jefferson' 'Hey, How are you?' -i /usr/share/icons/Tela-circle-dracula/scalable/apps/telegram.svg --action 'reply=Reply' --action 'ignore=Ignore' -u 'critical'"
				;;
esac

