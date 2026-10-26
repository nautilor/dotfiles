pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Material 3 Expressive tokens. Tonal roles are derived from one seed hue (Settings.hue),
// unless a colour scheme is selected (Settings.colorscheme), which supplies the colours instead.
Singleton {
	id: root

	readonly property real h: Settings.hue
	readonly property var pal: Colorschemes.palette
	function tone(s, l, hueShift) {
		return Qt.hsla((h + (hueShift || 0) + 1) % 1, s, l, 1);
	}

	// surfaces (the notch itself stays near-black so it merges with the screen edge)
	readonly property color notch: pal ? pal.notch : tone(0.12, 0.035)
	readonly property color surfaceContainerLow: pal ? pal.surfaceContainerLow : tone(0.16, 0.08)
	readonly property color surfaceContainer: pal ? pal.surfaceContainer : tone(0.17, 0.115)
	readonly property color surfaceContainerHigh: pal ? pal.surfaceContainerHigh : tone(0.18, 0.15)
	readonly property color surfaceContainerHighest: pal ? pal.surfaceContainerHighest : tone(0.18, 0.19)

	readonly property color primary: pal ? pal.primary : tone(0.55, 0.76)
	readonly property color primaryFg: pal ? pal.primaryFg : tone(0.65, 0.14)
	readonly property color primaryContainer: pal ? pal.primaryContainer : tone(0.45, 0.26)
	readonly property color primaryContainerFg: pal ? pal.primaryContainerFg : tone(0.65, 0.88)

	readonly property color secondaryContainer: pal ? pal.secondaryContainer : tone(0.22, 0.28, 0.02)
	readonly property color secondaryContainerFg: pal ? pal.secondaryContainerFg : tone(0.35, 0.88, 0.02)

	readonly property color tertiary: pal ? pal.tertiary : tone(0.5, 0.79, 0.16)
	readonly property color tertiaryFg: pal ? pal.tertiaryFg : tone(0.6, 0.15, 0.16)
	readonly property color tertiaryContainer: pal ? pal.tertiaryContainer : tone(0.38, 0.28, 0.16)
	readonly property color tertiaryContainerFg: pal ? pal.tertiaryContainerFg : tone(0.6, 0.9, 0.16)

	readonly property color error: pal ? pal.error : "#f2b8b5"
	readonly property color errorFg: pal ? pal.errorFg : "#601410"
	readonly property color errorContainer: pal ? pal.errorContainer : "#8c1d18"
	readonly property color errorContainerFg: pal ? pal.errorContainerFg : "#f9dedc"

	readonly property color surfaceFg: pal ? pal.surfaceFg : tone(0.1, 0.92)
	readonly property color surfaceVariantFg: pal ? pal.surfaceVariantFg : tone(0.1, 0.74)
	readonly property color outline: pal ? pal.outline : tone(0.08, 0.48)
	readonly property color outlineVariant: pal ? pal.outlineVariant : tone(0.1, 0.25)

	// type
	// JetBrainsMono Nerd Font (proportional variant) for text and for the Material Design Icons glyphs
	readonly property string font: "JetBrainsMono Nerd Font Propo"
	readonly property string iconFont: font

	// shape scale
	readonly property int radiusSmall: 12
	readonly property int radiusMedium: 18
	readonly property int radiusLarge: 28

	// motion: emphasized easing + springs that overshoot slightly (the "expressive" feel)
	readonly property var emphasized: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
	readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
	readonly property int durShort: 150
	readonly property int durMedium: 300
	readonly property int durLong: 500
	readonly property real springBouncy: 3.4
	readonly property real dampBouncy: 0.30
	readonly property real springSoft: 4.5
	readonly property real dampSoft: 0.42
}
