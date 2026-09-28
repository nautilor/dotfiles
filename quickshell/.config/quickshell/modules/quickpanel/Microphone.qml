import Quickshell
import QtQuick
import Quickshell.Io

Item {
    id: root

    readonly property bool muted:
        microphoneMuted === "true"

    property string microphoneMuted: "false"

    // ─────────────────────────────────────────────
    // Status
    // ─────────────────────────────────────────────

    Process {
        id: statusProcess

        command: [
            "bash",
            "-lc",
            "wpctl get-volume @DEFAULT_AUDIO_SOURCE@"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()

                /*
                 * wpctl returns something like:
                 *
                 * Volume: 1.00
                 *
                 * or:
                 *
                 * Volume: 1.00 [MUTED]
                 */

                root.microphoneMuted =
                    output.includes("[MUTED]")
                        ? "true"
                        : "false"
            }
        }
    }

    // ─────────────────────────────────────────────
    // Toggle
    // ─────────────────────────────────────────────

    Process {
        id: toggleProcess

        command: [
            "wpctl",
            "set-mute",
            "@DEFAULT_AUDIO_SOURCE@",
            "toggle"
        ]

        onRunningChanged: {
            if (!running)
                statusProcess.running = true
        }
    }

    // ─────────────────────────────────────────────
    // Periodic state refresh
    // ─────────────────────────────────────────────

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (!statusProcess.running && !toggleProcess.running)
                statusProcess.running = true
        }
    }

    // ─────────────────────────────────────────────
    // Quick Toggle
    // ─────────────────────────────────────────────

    QuickToggle {
        id: toggle

        anchors.fill: parent

        checked: !root.muted

        activeIcon: "󰍬"
        inactiveIcon: "󰍭"

        label: "Microphone"

        subLabel: root.muted
            ? "Muted"
            : "On"

        onToggled: {
            if (!toggleProcess.running)
                toggleProcess.running = true
        }
    }
}
