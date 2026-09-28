import Quickshell
import QtQuick
import Quickshell.Services.UPower
import qs.modules.bar.components
import qs.modules.colors

Item {
	id: root

	Colors {
		id: colors
	}

	readonly property var battery: UPower.displayDevice
	readonly property real batteryPercentage: battery?.percentage ?? 0
	readonly property bool batteryPluggedIn: battery?.state === UPowerDeviceState.Charging
	|| battery?.state === UPowerDeviceState.FullyCharged
	readonly property bool batteryLow: battery
	&& battery.ready
	&& battery.isPresent
	&& battery.isLaptopBattery
	&& !batteryPluggedIn
	&& batteryPercentage <= 0.15

	readonly property color chargingColor: colors.success
	readonly property color lowBatteryColor: colors.critical



	Indicator {
		backgroundColor: root.batteryPluggedIn ? root.chargingColor : root.lowBatteryColor
		foregroundColor: colors.windowBackground
		icon: root.batteryPluggedIn ? "󰂄" : "󰂃"
		visible: root.batteryLow || root.batteryPluggedIn
	}
}
