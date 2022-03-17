if [ -z "$WINID" ]; then
    echo "(box :orientation \"v\" :class \"non-tabbed-window\" :halign \"center\" :valign \"center\" :vexpand true :hexpand true \"\")"
    exit
fi
WINCLASS=$(xprop -id "$WINID" | grep WM_CLASS)

if [[ "$WINCLASS" =~ "tabbed" ]]; then
    echo "(box :orientation \"v\" :class \"non-tabbed-window\" :halign \"center\" :valign \"center\" :vexpand true :hexpand true \"\")"
else
    echo "(box :orientation \"v\" :class \"tabbed-window\" :halign \"center\" :valign \"center\" :vexpand true :hexpand true \"\")"
fi