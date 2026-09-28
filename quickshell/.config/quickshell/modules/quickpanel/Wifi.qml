import Quickshell
import QtQuick
import Quickshell.Networking

Item {
    id: root

    readonly property var wifiDevice: {
        const devices = Networking.devices.values || [];

        return devices.find(
            device => device && device.type === DeviceType.Wifi
        ) || null;
    }

    readonly property var activeNetwork: {
        const device = root.wifiDevice;

        if (!device)
            return null;

        const networks = device.networks.values || [];

        return networks.find(
            network => network && network.connected
        ) || null;
    }

    readonly property bool wifiAvailable:
        Networking.wifiHardwareEnabled

    readonly property bool wifiEnabled:
        Networking.wifiEnabled

    readonly property bool connected:
        root.activeNetwork !== null

    readonly property real signalStrength:
        root.activeNetwork
            ? root.activeNetwork.signalStrength
            : 0

    readonly property string networkName:
        root.activeNetwork
            ? root.activeNetwork.name
            : ""

    function wifiIcon() {
        if (!Networking.wifiEnabled)
            return "󰤭";

        if (!root.wifiDevice || !root.activeNetwork)
            return "󰤭";

        const strength = root.signalStrength * 100;

        if (strength >= 80)
            return "󰤨";

        if (strength >= 55)
            return "󰤥";

        if (strength >= 30)
            return "󰤢";

        if (strength > 0)
            return "󰤟";

        return "󰤯";
    }

    QuickToggle {
        id: toggle

        anchors.fill: parent

        enabled:
            root.wifiAvailable

        checked:
            root.wifiEnabled

        activeIcon:
            root.wifiIcon()

        inactiveIcon:
            "󰤭"

        label:
            "Wi-Fi"

        subLabel: {
            if (!root.wifiAvailable)
                return "Unavailable";

            if (!root.wifiEnabled)
                return "Off";

            if (root.connected)
                return root.networkName;

            return "Not connected";
        }

        onToggled: {
            Networking.wifiEnabled = !Networking.wifiEnabled;
        }
    }
}
