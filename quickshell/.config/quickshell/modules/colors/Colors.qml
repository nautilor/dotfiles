import Quickshell
import QtQuick

QtObject {
	// ─────────────────────────────────────────────
	// Material You — Deep City / Night
	// Designed for dark blue/cyan wallpapers
	// ─────────────────────────────────────────────

	readonly property color background: "#070D11"
	readonly property color surface: "#0A1217"
	readonly property color surfaceContainerLowest: "#050A0D"
	readonly property color surfaceContainerLow: "#0D171D"
	readonly property color surfaceContainer: "#111D24"
	readonly property color surfaceContainerHigh: "#17252D"
	readonly property color surfaceContainerHighest: "#1E2D36"
	readonly property color surfaceVariant: "#263943"

	// ─────────────────────────────────────────────
	// Primary — atmospheric cyan / blue
	// ─────────────────────────────────────────────

	readonly property color primary: "#8CC8D9"
	readonly property color primaryForeground: "#07313A"
	readonly property color primaryContainer: "#16414C"
	readonly property color primaryContainerForeground: "#B8E6F0"

	// ─────────────────────────────────────────────
	// Secondary — steel blue
	// ─────────────────────────────────────────────

	readonly property color secondary: "#A7C4CC"
	readonly property color secondaryForeground: "#102B32"
	readonly property color secondaryContainer: "#29434B"
	readonly property color secondaryContainerForeground: "#C3E0E6"

	// ─────────────────────────────────────────────
	// Tertiary — muted city-light amber
	// ─────────────────────────────────────────────

	readonly property color tertiary: "#E1C18A"
	readonly property color tertiaryForeground: "#352A13"
	readonly property color tertiaryContainer: "#4A3A1D"
	readonly property color tertiaryContainerForeground: "#F5DDAA"

	// ─────────────────────────────────────────────
	// Text
	// ─────────────────────────────────────────────

	readonly property color surfaceForeground: "#D8E3E7"
	readonly property color surfaceVariantForeground: "#9EAFB6"

	// ─────────────────────────────────────────────
	// Outlines
	// ─────────────────────────────────────────────

	readonly property color outline: "#71858D"
	readonly property color outlineVariant: "#35474F"

	// ─────────────────────────────────────────────
	// Error
	// ─────────────────────────────────────────────

	readonly property color error: "#FFB4AB"
	readonly property color errorContainer: "#641D20"
	readonly property color errorContainerForeground: "#FFDAD6"

	// ─────────────────────────────────────────────
	// Warning
	// ─────────────────────────────────────────────

	readonly property color warning: "#E4C275"
	readonly property color warningContainer: "#463718"
	readonly property color warningContainerForeground: "#F7DEA6"

	// ─────────────────────────────────────────────
	// Success — cool green, not neon
	// ─────────────────────────────────────────────

	readonly property color success: "#9CC9A5"
	readonly property color successContainer: "#23432D"
	readonly property color successContainerForeground: "#BFE8C5"

	// ─────────────────────────────────────────────
	// Shape
	// ─────────────────────────────────────────────

	readonly property int radiusNone: 0
	readonly property int radiusExtraSmall: 4
	readonly property int radiusSmall: 8
	readonly property int radiusMedium: 12
	readonly property int radiusLarge: 16
	readonly property int radiusLargeIncreased: 20
	readonly property int radiusExtraLarge: 28
	readonly property int radiusHero: 48
	readonly property int radiusFull: 999

	// ─────────────────────────────────────────────
	// Sizes
	// ─────────────────────────────────────────────

	readonly property int sizeXs: 32
	readonly property int sizeSmall: 40
	readonly property int sizeMedium: 48
	readonly property int sizeLarge: 56
	readonly property int sizeExtraLarge: 64

	// ─────────────────────────────────────────────
	// Typography
	// ─────────────────────────────────────────────

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

	// ─────────────────────────────────────────────
	// Spacing
	// ─────────────────────────────────────────────

	readonly property int spacing2: 2
	readonly property int spacing4: 4
	readonly property int spacing8: 8
	readonly property int spacing12: 12
	readonly property int spacing16: 16
	readonly property int spacing20: 20
	readonly property int spacing24: 24
	readonly property int spacing32: 32

	// ─────────────────────────────────────────────
	// Animation
	// ─────────────────────────────────────────────

	readonly property int effectsDuration: 180
	readonly property int spatialDuration: 280

	// ─────────────────────────────────────────────
	// Compatibility aliases
	// ─────────────────────────────────────────────

	readonly property color windowBackground: background
	readonly property color windowForeground: surfaceForeground

	readonly property color foreground: surfaceForeground
	readonly property color foregroundMuted: surfaceVariantForeground

	readonly property color accentColor: primary
	readonly property color critical: error

	// ─────────────────────────────────────────────
	// QuickShell
	// ─────────────────────────────────────────────

	readonly property color quickPanelBackground: surface
	readonly property color quickToggleBackground: surfaceContainer
	readonly property color quickToggleForeground: surfaceForeground

	readonly property color quickToggleActiveBackground: primary
	readonly property color quickToggleActiveForeground: primaryForeground
}

