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
	property string messageText: ""
	property string messageIcon: ""

	readonly property int osdWidth: 340
	readonly property int osdHeight: 64
	readonly property int messageMaxWidth: 420
	readonly property int messageMinWidth: 220
	readonly property int messageIconSize: 30
	readonly property int messageSpacing: 12
	readonly property int messagePaddingX: 18

	TextMetrics {
		id: messageMetrics
		text: osd.messageText
		font.pixelSize: 14
		font.weight: Font.DemiBold
	}

	readonly property int messagePillWidth: {
		// icon + spacing + text, plus horizontal padding on both sides
		const textWidth = messageMetrics.width || 0;
		const contentWidth = messageIconSize + messageSpacing + textWidth;
		const width = Math.ceil(contentWidth + (messagePaddingX * 2));
		return Math.min(messageMaxWidth, Math.max(messageMinWidth, width));
	}

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

	function showMessage(iconName, text) {
		mode = "message";
		messageIcon = iconName || "";
		messageText = text || "";
		shouldShowOsd = true;
		hideTimer.restart();
	}

	// Map certain message/icon names to Nerd Font glyphs so OSD doesn't rely on the icon theme.
	function glyphFor(name) {
		if (!name)
			return "";
		switch (name) {
		case "caffeine":
		case "caffeine-off":
			return "󰅶"; // caffeine glyph used elsewhere in configs
		case "microphone-sensitivity-muted":
			return "󰍭"; // mic muted glyph (used in waybar)
		case "microphone-sensitivity-high":
			return "󰍰"; // mic (unmuted) - fallback glyph
		default:
			return "";
		}
	}

	readonly property string iconName: {
		if (mode === "message")
			return messageIcon;
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

	Process {
		id: caffeineStateReader
		command: ["bash", "-lc", 'bash "$HOME/.config/hypr/bin/caffeine.sh" state 2>/dev/null || true']
		stdout: StdioCollector {
			onStreamFinished: {
				const state = (this.text || "").trim();
				if (state === "active")
					osd.showMessage("caffeine", "Caffeine active");
				else if (state === "inactive")
					osd.showMessage("caffeine-off", "Caffeine inactive");
				else
					osd.showMessage("caffeine", "Caffeine");
			}
		}
	}

	Process {
		id: micStateReader
		command: ["bash", "-lc", 'bash "$HOME/.config/hypr/bin/mic_toggle.sh" state 2>/dev/null || true']
		stdout: StdioCollector {
			onStreamFinished: {
				const state = (this.text || "").trim();
				if (state === "muted")
					osd.showMessage("microphone-sensitivity-muted", "Microphone muted");
				else if (state === "unmuted")
					osd.showMessage("microphone-sensitivity-high", "Microphone unmuted");
				else
					osd.showMessage("microphone-sensitivity-high", "Microphone");
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

		function caffeine() {
			if (!caffeineStateReader.running)
				caffeineStateReader.running = true;
		}

		function mic() {
			if (!micStateReader.running)
				micStateReader.running = true;
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

			readonly property int shadowPadding: 16

			// Ubuntu-like OSD: a bit taller and less wide.
			implicitWidth: (osd.mode === "message" ? osd.messagePillWidth : osd.osdWidth) + (shadowPadding * 2)
			implicitHeight: osd.osdHeight + (shadowPadding * 2)
			color: "transparent"

			// Prevent blocking mouse events behind the overlay
			mask: Region {}

			RectangularShadow {
				anchors.fill: container
				radius: container.radius
				color: Qt.darker(theme.panelBgPrimary, 1.6)
				blur: 5
				spread: 0.2
				offset: Qt.point(0, 4)
			}

			Rectangle {
				id: container
				anchors.fill: parent
				anchors.margins: shadowPadding
				radius: height / 2
				color: theme.panelBgPrimary
				border.width: 0
				border.color: Qt.rgba(1, 1, 1, 0.08)

				RowLayout {
					id: messageRow
					visible: osd.mode === "message"
					anchors.centerIn: parent
					spacing: osd.messageSpacing

					Item {
						id: messageIconItem
						implicitWidth: osd.messageIconSize
						implicitHeight: osd.messageIconSize

						property string iName: osd.messageIcon
						property string glyph: osd.glyphFor(iName)

						Text {
							anchors.fill: parent
							visible: messageIconItem.glyph !== ""
							text: messageIconItem.glyph
							color: theme.panelTextPrimary
							font.pixelSize: osd.messageIconSize
							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
						}

						IconImage {
							anchors.fill: parent
							visible: messageIconItem.glyph === ""
							implicitSize: osd.messageIconSize
							source: Quickshell.iconPath(messageIconItem.iName)
						}
					}

					Text {
						text: osd.messageText
						color: theme.panelTextPrimary
						font.pixelSize: 14
						font.weight: Font.DemiBold
						elide: Text.ElideRight
						maximumLineCount: 1
						verticalAlignment: Text.AlignVCenter

						readonly property int maxW: osd.messageMaxWidth - (osd.messagePaddingX * 2) - osd.messageIconSize - osd.messageSpacing
						Layout.preferredWidth: Math.min(implicitWidth, maxW)
					}
				}

				RowLayout {
					visible: osd.mode !== "message"
					anchors {
						fill: parent
						leftMargin: 16
						rightMargin: 18
					}
					spacing: 14

					Item {
						id: volumeIconItem
						implicitWidth: 30
						implicitHeight: 30

						property string iName: osd.iconName
						property string glyph: osd.glyphFor(iName)

						Text {
							anchors.fill: parent
							visible: volumeIconItem.glyph !== ""
							text: volumeIconItem.glyph
							color: theme.panelTextPrimary
							font.pixelSize: 30
							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
						}

						IconImage {
							anchors.fill: parent
							visible: volumeIconItem.glyph === ""
							implicitSize: 30
							source: Quickshell.iconPath(volumeIconItem.iName)
						}
					}

					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 8
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
