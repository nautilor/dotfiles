import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import "../shared" as Shared

Scope {
	id: osd

	Shared.Theme { id: theme }

	property bool shouldShowOsd: false
	property string mode: ""
	property real level: 0.0 // 0..1 for the progress bar
	property int percent: 0
	property bool muted: false

	property int brightnessPercent: 0
	property bool brightnessReady: false

	function clamp01(value) {
		if (value === undefined || value === null)
			return 0;
		return Math.max(0, Math.min(1, value));
	}

	function showVolume() {
		const sink = Pipewire.defaultAudioSink;
		const audio = sink ? sink.audio : null;
		if (!audio)
			return;

		const raw = audio.volume !== undefined && audio.volume !== null ? audio.volume : 0;
		const isMuted = audio.muted !== undefined && audio.muted !== null ? audio.muted : false;

		mode = "volume";
		muted = isMuted;
		percent = Math.round(raw * 100);
		level = clamp01(raw);

		shouldShowOsd = true;
		hideTimer.restart();
	}

	function showBrightness(nextPercent) {
		mode = "brightness";
		muted = false;
		percent = nextPercent;
		level = clamp01(nextPercent / 100);

		shouldShowOsd = true;
		hideTimer.restart();
	}

	readonly property string iconName: {
		if (mode === "brightness")
			return "display-brightness-symbolic";

		if (muted || percent <= 0)
			return "audio-volume-muted-symbolic";
		if (percent < 34)
			return "audio-volume-low-symbolic";
		if (percent < 67)
			return "audio-volume-medium-symbolic";
		return "audio-volume-high-symbolic";
	}

	PwObjectTracker {
		objects: [Pipewire.defaultAudioSink]
	}

	Connections {
		target: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio : null

		function onVolumeChanged() {
			osd.showVolume();
		}

		function onMutedChanged() {
			osd.showVolume();
		}
	}

	Process {
		id: brightnessReader
		command: [
			"bash",
			"-lc",
			"brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, \"\", $4); print int($4); found = 1 } END { if (!found) print \"0\" }'"
		]
		stdout: StdioCollector {
			onStreamFinished: {
				const text = this.text.trim();
				if (text === "")
					return;

				const next = parseInt(text);
				if (Number.isNaN(next))
					return;

				if (!osd.brightnessReady) {
					osd.brightnessReady = true;
					osd.brightnessPercent = next;
					return;
				}

				if (next !== osd.brightnessPercent) {
					osd.brightnessPercent = next;
					osd.showBrightness(next);
				}
			}
		}
	}

	Process {
		id: brightnessPokeReader
		command: [
			"bash",
			"-lc",
			"brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, \"\", $4); print int($4); found = 1 } END { if (!found) print \"0\" }'"
		]
		stdout: StdioCollector {
			onStreamFinished: {
				const text = this.text.trim();
				if (text === "")
					return;

				const next = parseInt(text);
				if (Number.isNaN(next))
					return;

				osd.brightnessReady = true;
				osd.brightnessPercent = next;
				osd.showBrightness(next);
			}
		}
	}

	IpcHandler {
		target: "osd"

		// Parameterless IPC functions (these show up in `qs ipc show`).
		function volume() {
			osd.showVolume();
		}

		function brightness() {
			if (!brightnessPokeReader.running)
				brightnessPokeReader.running = true;
		}
	}

	Timer {
		interval: 250
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			if (!brightnessReader.running)
				brightnessReader.running = true;
		}
	}

	Timer {
		id: hideTimer
		interval: 1200
		onTriggered: osd.shouldShowOsd = false
	}

	LazyLoader {
		active: osd.shouldShowOsd

		PanelWindow {
			anchors.bottom: true
			margins.bottom: screen.height / 5
			exclusiveZone: 0

			implicitWidth: 420
			implicitHeight: 56
			color: "transparent"

			// Prevent blocking mouse events behind the overlay
			mask: Region {}

			RectangularShadow {
				anchors.fill: parent
				radius: height / 2
				color: Qt.rgba(0, 0, 0, 0.25)
				blur: 5
				spread: 0.2
				offset: Qt.point(0, 4)
			}

			Rectangle {
				id: container
				anchors.fill: parent
				radius: height / 2
				color: theme.panelBgPrimary
				border.width: 0
				border.color: Qt.rgba(1, 1, 1, 0.08)

				RowLayout {
					anchors {
						fill: parent
						leftMargin: 14
						rightMargin: 16
					}
					spacing: 12

					IconImage {
						implicitSize: 26
						source: Quickshell.iconPath(osd.iconName)
					}

					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 10
						radius: 20
						color: theme.panelTrack

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}
							width: parent.width * osd.level
							radius: parent.radius
							color: theme.panelAccent
						}
					}

					Text {
						text: `${osd.percent}%`
						color: theme.panelTextPrimary
						font.pixelSize: 14
						font.weight: Font.DemiBold
						verticalAlignment: Text.AlignVCenter
					}
				}
			}
		}
	}
}
