pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
	id: root

	readonly property var device: UPower.displayDevice
	readonly property bool present: device !== null && device.isLaptopBattery
	readonly property int percent: present ? Math.round(device.percentage * 100) : 0
	readonly property bool charging: present && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
	readonly property string icon: {
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
