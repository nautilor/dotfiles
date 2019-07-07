function fish_prompt
	set -l last_status $status
	set __git_cb "<"(git branch ^/dev/null | grep \* | sed 's/* //')">"
	echo -n -s (hostname)
	set_color -o red
	echo -n -s ' :: ' 
	set_color -o green
	echo -n -s (prompt_pwd)
	set_color blue 
	printf ' %s' $__git_cb
	echo -n -s ' % '
	set_color normal
end
