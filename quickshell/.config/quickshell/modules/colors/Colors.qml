import Quickshell
import QtQuick

QtObject {
	readonly property color background: "#080A0D"
	readonly property color surface: "#0B0D10"
	readonly property color surfaceContainerLow: "#101318"
	readonly property color surfaceContainer: "#15191F"
	readonly property color surfaceContainerHigh: "#1B2027"
	readonly property color surfaceContainerHighest: "#222830"
	readonly property color surfaceVariant: "#29313A"

	// One Dark Pro blue
	readonly property color primary: "#61AFEF"
	readonly property color primaryForeground: "#071018"
	readonly property color primaryContainer: "#18344A"
	readonly property color primaryContainerForeground: "#B9DEFF"

	// One Dark Pro cyan/blue
	readonly property color secondary: "#56B6C2"
	readonly property color secondaryForeground: "#071113"
	readonly property color secondaryContainer: "#16363B"
	readonly property color secondaryContainerForeground: "#B9F0F5"

	// One Dark Pro purple
	readonly property color tertiary: "#C678DD"
	readonly property color tertiaryForeground: "#170B1B"
	readonly property color tertiaryContainer: "#382043"
	readonly property color tertiaryContainerForeground: "#F0C9FA"

	// Text
	readonly property color surfaceForeground: "#ABB2BF"
	readonly property color surfaceVariantForeground: "#7F8793"
	readonly property color outline: "#4B5360"
	readonly property color outlineVariant: "#303741"

	// One Dark Pro red
	readonly property color error: "#E06C75"
	readonly property color errorContainer: "#4A2025"
	readonly property color errorContainerForeground: "#FFB7BD"

	// One Dark Pro yellow
	readonly property color warning: "#E5C07B"
	readonly property color warningContainer: "#40351D"
	readonly property color warningContainerForeground: "#F8DFA8"

	// One Dark Pro green
	readonly property color success: "#98C379"
	readonly property color successContainer: "#263A20"
	readonly property color successContainerForeground: "#C8E9B3"

	readonly property int radiusNone: 0
	readonly property int radiusExtraSmall: 4
	readonly property int radiusSmall: 8
	readonly property int radiusMedium: 12
	readonly property int radiusLarge: 16
	readonly property int radiusLargeIncreased: 20
	readonly property int radiusExtraLarge: 28
	readonly property int radiusHero: 48
	readonly property int radiusFull: 999

	readonly property int sizeXs: 32
	readonly property int sizeSmall: 40
	readonly property int sizeMedium: 48
	readonly property int sizeLarge: 56
	readonly property int sizeExtraLarge: 64

	readonly property int displaySmall: 36
	readonly property int headlineSmall: 24
	readonly property int titleLarge: 22
	readonly property int titleMedium: 16
	readonly property int titleSmall: 14
	readonly property int bodyLarge: 16
	readonly property int bodyMedium: 14
	readonly property int bodySmall: 12
	readonly property int labelLarge: 14
	readonly property int labelMedium: 12
	readonly property int labelSmall: 11

	readonly property int spacing2: 2
	readonly property int spacing4: 4
	readonly property int spacing8: 8
	readonly property int spacing12: 12
	readonly property int spacing16: 16
	readonly property int spacing20: 20
	readonly property int spacing24: 24
	readonly property int spacing32: 32

	readonly property int effectsDuration: 180
	readonly property int spatialDuration: 280

	readonly property color windowBackground: background
	readonly property color windowForeground: surfaceForeground
	readonly property color foreground: surfaceForeground
	readonly property color foregroundMuted: surfaceVariantForeground
	readonly property color accentColor: primary
	readonly property color critical: error

readonly property color quickPanelBackground: background
readonly property color quickToggleBackground: surfaceContainer
readonly property color quickToggleForeground: surfaceForeground
readonly property color quickToggleActiveBackground: primary
readonly property color quickToggleActiveForeground: primaryForeground
}

