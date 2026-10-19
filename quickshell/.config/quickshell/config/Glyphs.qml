pragma Singleton

import QtQuick
import Quickshell

// Icon names (Material Symbols vocabulary) -> Material Design Icons code points shipped in Nerd Fonts.
Singleton {
	readonly property var codes: ({
		"add": 0xf0415,
		"edit": 0xf03eb,
		"visibility_off": 0xf0209,
		"delete": 0xf01b4,
		"save": 0xf0193,
		"place": 0xf034e,
		"schedule": 0xf0150,
		"apps": 0xf003b,
		"arrow_back": 0xf004d,
		"balance": 0xf05d1,
		"bedtime": 0xf04b2,
		"bluetooth": 0xf00af,
		"bluetooth_disabled": 0xf00b2,
		"bolt": 0xf0241,
		"brightness_5": 0xf00de,
		"brightness_7": 0xf00e0,
		"calendar_month": 0xf0e17,
		"check": 0xf012c,
		"chevron_left": 0xf0141,
		"chevron_right": 0xf0142,
		"clear_all": 0xf039f,
		"close": 0xf0156,
		"coffee": 0xf0176,
		"content_paste": 0xf014d,
		"delete_sweep": 0xf05e9,
		"eco": 0xf032a,
		"event": 0xf09d3,
		"event_busy": 0xf00f4,
		"home": 0xf02dc,
		"image": 0xf02e9,
		"lock": 0xf033e,
		"login": 0xf0342,
		"logout": 0xf0343,
		"mic": 0xf036c,
		"mic_off": 0xf036d,
		"music_note": 0xf0387,
		"music_off": 0xf075b,
		"notes": 0xf039e,
		"notifications": 0xf009a,
		"notifications_active": 0xf009e,
		"notifications_off": 0xf009b,
		"notifications_paused": 0xf00a0,
		"pause": 0xf03e4,
		"play_arrow": 0xf040a,
		"power_settings_new": 0xf0425,
		"push_pin": 0xf0403,
		"refresh": 0xf0450,
		"remove": 0xf0374,
		"restart_alt": 0xf0709,
		"search": 0xf0349,
		"skip_next": 0xf04ad,
		"skip_previous": 0xf04ae,
		"sync": 0xf04e6,
		"tune": 0xf062e,
		"volume_down": 0xf0580,
		"volume_up": 0xf057e,
		"volume_mute": 0xf057f,
		"volume_off": 0xf0581,
		"wifi": 0xf05a9,
		"wifi_off": 0xf05aa,
		"battery_full": 0xf0079,
		"battery_5_bar": 0xf0080,
		"battery_4_bar": 0xf007e,
		"battery_3_bar": 0xf007c,
		"battery_1_bar": 0xf007a,
		"battery_charging_full": 0xf0084
	})

	function get(name) {
		const c = codes[name];
		return c === undefined ? "" : String.fromCodePoint(c);
	}
}
