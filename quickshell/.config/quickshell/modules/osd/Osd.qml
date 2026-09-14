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
	readonly property int osdHeight: 72
	readonly property int messageMaxWidth: 440
	readonly property int messageMinWidth: 240
	readonly property int messageIconSize: 30
	readonly property int messageBubbleSize: 40
	readonly property int messageSpacing: 12
	readonly property int messagePaddingX: 16
	readonly property int messagePaddingY: 12

	TextMetrics {
		id: messageMetrics
		text: osd.messageText
		font.pixelSize: 14
		font.weight: Font.DemiBold
	}

	TextMetrics {
		id: messageTitleMetrics
		text: osd.messageTitle
		font.pixelSize: 14
		font.weight: Font.DemiBold
	}

	TextMetrics {
		id: messageSubtitleMetrics
		text: osd.messageText
		font.pixelSize: 12
		font.weight: Font.Medium
	}

	TextMetrics {
		id: percentMetrics
		text: "100%"
		font.pixelSize: 14
		font.weight: Font.DemiBold
	}

	function isToggleMessage(name) {
		return ["caffeine", "caffeine-off", "microphone-sensitivity-muted", "microphone-sensitivity-high"].indexOf(name) !== -1;
	}

	function messageTitleFor(name) {
		switch (name) {
		case "caffeine":
		case "caffeine-off":
			return "Caffeine";
		case "microphone-sensitivity-muted":
		case "microphone-sensitivity-high":
			return "Microphone";
		default:
			return messageText;
		}
	}

	function accentContainerFor(name) {
		switch (name) {
		case "caffeine":
			return theme.primaryContainer;
		case "caffeine-off":
			return theme.surfaceVariant;
		case "microphone-sensitivity-muted":
			return theme.errorContainer;
		case "microphone-sensitivity-high":
			return theme.secondaryContainer;
		default:
			return theme.primaryContainer;
		}
	}

	function accentTextFor(name) {
		switch (name) {
		case "caffeine":
			return theme.primaryContainerText;
		case "caffeine-off":
			return theme.surfaceVariantText;
		case "microphone-sensitivity-muted":
			return theme.errorContainerText;
		case "microphone-sensitivity-high":
			return theme.secondaryContainerText;
		default:
			return theme.primaryContainerText;
		}
	}

	readonly property bool messageToggle: mode === "message" && isToggleMessage(messageIcon)

	readonly property string messageTitle: {
		if (mode !== "message")
			return "";
		return messageToggle ? messageTitleFor(messageIcon) : messageText;
	}

	readonly property color messageAccentContainer: accentContainerFor(messageIcon)
	readonly property color messageAccentText: accentTextFor(messageIcon)

	readonly property int messageIconPillWidth: {
		const textWidth = messageMetrics.width || 0;
		const contentWidth = messageIconSize + messageSpacing + textWidth;
		const width = Math.ceil(contentWidth + (messagePaddingX * 2));
		return Math.min(messageMaxWidth, Math.max(messageMinWidth, width));
	}
	readonly property int messageTogglePillWidth: {
		const textWidth = Math.max(messageTitleMetrics.width || 0, messageSubtitleMetrics.width || 0);
		const contentWidth = messageBubbleSize + messageSpacing + textWidth;
		const width = Math.ceil(contentWidth + (messagePaddingX * 2));
		return Math.min(messageMaxWidth, Math.max(messageMinWidth, width));
	}
	readonly property int messagePillWidth: {
		if (mode === "message" && messageToggle)
			return messageTogglePillWidth;

		const textWidth = messageMetrics.width || 0;
		const contentWidth = messageIconSize + messageSpacing + textWidth;
		const width = Math.ceil(contentWidth + (messagePaddingX * 2));
		return Math.min(messageMaxWidth, Math.max(messageMinWidth, width));
	}

	readonly property int messagePillHeight: mode === "message" && messageToggle ? 76 : 72

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
			return "󰍬"; // mic (unmuted) - fallback glyph
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
		command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/caffeine.sh" state 2>/dev/null || true']
		stdout: StdioCollector {
			onStreamFinished: {
				const state = (this.text || "").trim();
				if (state === "active")
					osd.showMessage("caffeine", "On");
				else if (state === "inactive")
					osd.showMessage("caffeine-off", "Off");
				else
					osd.showMessage("caffeine", "Caffeine");
			}
		}
	}

	Process {
		id: micStateReader
		command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/mic_toggle.sh" state 2>/dev/null || true']
		stdout: StdioCollector {
			onStreamFinished: {
				const state = (this.text || "").trim();
				if (state === "muted")
					osd.showMessage("microphone-sensitivity-muted", "Muted");
				else if (state === "unmuted")
					osd.showMessage("microphone-sensitivity-high", "On");
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
			readonly property color surfaceTint: Qt.alpha(theme.primary, 0.08)

			// Android-like OSD: rounded pill with a softer elevated surface.
			implicitWidth: (osd.mode === "message" ? osd.messagePillWidth : osd.osdWidth) + (shadowPadding * 2)
			implicitHeight: (osd.mode === "message" ? osd.messagePillHeight : osd.osdHeight) + (shadowPadding * 2)
			color: "transparent"

			// Prevent blocking mouse events behind the overlay
			mask: Region {}

			RectangularShadow {
				anchors.fill: container
				radius: container.radius
				color: Qt.darker(theme.background, 1.6)
				blur: 5
				spread: 0.2
				offset: Qt.point(0, 4)
			}

			Rectangle {
				id: container
				anchors.fill: parent
				anchors.margins: shadowPadding
				radius: height / 2
				color: theme.surfaceContainerHigh
				opacity: 0.98
				border.width: 1
				border.color: Qt.alpha(theme.outline, 0.35)
				clip: true

				Rectangle {
					anchors.fill: parent
					radius: parent.radius
					color: surfaceTint
				}

				Item {
					visible: osd.mode === "message"
					anchors.fill: parent

					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: osd.messagePaddingX
						anchors.rightMargin: osd.messagePaddingX
						anchors.topMargin: osd.messagePaddingY
						anchors.bottomMargin: osd.messagePaddingY
						spacing: osd.messageSpacing

						Item {
							id: messageIconItem
							Layout.preferredWidth: osd.messageBubbleSize
							Layout.preferredHeight: osd.messageBubbleSize

							property string iName: osd.messageIcon
							property string glyph: osd.glyphFor(iName)

							Rectangle {
								anchors.fill: parent
								radius: width / 2
								color: Qt.alpha(osd.messageAccentContainer, osd.messageToggle ? 1.0 : 0.65)
								border.width: 1
								border.color: Qt.alpha(osd.messageAccentContainer, 0.32)
							}

							Text {
								anchors.fill: parent
								visible: messageIconItem.glyph !== ""
								text: messageIconItem.glyph
								color: osd.messageAccentText
								font.pixelSize: 20
								font.weight: Font.DemiBold
								font.family: "JetBrainsMono Nerd Font Propo"
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

						ColumnLayout {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignVCenter
							spacing: 1

							Text {
								Layout.fillWidth: true
								text: osd.messageTitle
								color: theme.surfaceText
								font.pixelSize: 14
								font.weight: Font.DemiBold
								elide: Text.ElideRight
								maximumLineCount: 1
								verticalAlignment: Text.AlignVCenter
							}

							Text {
								visible: osd.messageToggle
								Layout.fillWidth: true
								text: osd.messageText
								color: theme.surfaceVariantText
								font.pixelSize: 12
								font.weight: Font.Medium
								elide: Text.ElideRight
								maximumLineCount: 1
								verticalAlignment: Text.AlignVCenter
							}
						}
					}
				}

				RowLayout {
					visible: osd.mode !== "message"
					anchors {
						fill: parent
						leftMargin: 16
						rightMargin: 16
					}
					spacing: 12

					Item {
						id: volumeIconItem
						implicitWidth: 40
						implicitHeight: 40

						property string iName: osd.iconName
						property string glyph: osd.glyphFor(iName)

						Rectangle {
							anchors.fill: parent
							radius: width / 2
							color: Qt.alpha(theme.primaryContainer, 0.8)
							border.width: 1
							border.color: Qt.alpha(theme.primaryContainer, 0.28)
						}

						Text {
							anchors.fill: parent
							visible: volumeIconItem.glyph !== ""
							text: volumeIconItem.glyph
							color: theme.primaryContainerText
							font.pixelSize: 26
							font.weight: Font.DemiBold
							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
						}

						IconImage {
							anchors.fill: parent
							visible: volumeIconItem.glyph === ""
							implicitSize: 26
							source: Quickshell.iconPath(volumeIconItem.iName)
						}
					}

					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 10
						radius: 20
						color: theme.track

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}
							width: parent.width * osd.level
							radius: parent.radius
							color: theme.primary
						}
					}

					Rectangle {
						implicitWidth: percentMetrics.width + 18
						implicitHeight: 28
						radius: height / 2
						color: theme.surfaceVariant
						border.width: 0

						Text {
							anchors.centerIn: parent
							text: `${osd.percent}%`
							color: theme.surfaceText
							font.pixelSize: 13
							font.weight: Font.DemiBold
							verticalAlignment: Text.AlignVCenter
							horizontalAlignment: Text.AlignRight
						}
					}
				}
			}
		}
	}
}
