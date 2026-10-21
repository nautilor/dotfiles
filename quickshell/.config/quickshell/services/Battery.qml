pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config

Singleton {
	id: root

	readonly property var device: UPower.displayDevice
	readonly property bool present: device !== null && device.isLaptopBattery
	readonly property int percent: present ? Math.round(device.percentage * 100) : 0
	readonly property bool charging: present && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
	readonly property bool full: present && (device.state === UPowerDeviceState.FullyCharged || (charging && percent >= 99))
	readonly property bool low: present && !charging && percent <= 20
	// green while charging, accent when full, red when low, neutral otherwise
	readonly property color color: full ? Theme.primary : charging ? "#7bd88f" : low ? Theme.error : Theme.surfaceVariantFg
	readonly property string icon: {
		if (full)
			return "battery_full";
		if (charging)
			return "battery_charging_full";
		if (percent > 90)
			return "battery_full";
		if (percent > 65)
			return "battery_5_bar";
		if (percent > 40)
			return "battery_4_bar";
		if (percent > 20)
			return "battery_3_bar";
		return "battery_1_bar";
	}
}
