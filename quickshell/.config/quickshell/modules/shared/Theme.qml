import QtQuick

QtObject {
	// Load custom colors if exist, else use defaults
	property QtObject matugen: {
		var component = Qt.createComponent(Qt.resolvedUrl("Matugen.qml"));
		if (component.status === Component.Ready) {
			return component.createObject(this);
		}
		return null;
	}
// ========== Material Design 3 Color System ==========

// Primary - main brand color
readonly property color primary: matugen ? matugen.primary : "#6689D0"
readonly property color primaryText: matugen ? matugen.primaryText : "#101017"
readonly property color primaryContainer: matugen ? matugen.primaryContainer : "#252D46"
readonly property color primaryContainerText: matugen ? matugen.primaryContainerText : "#B8C3E5"

// Secondary - complementary accent
readonly property color secondary: matugen ? matugen.secondary : "#67B5D1"
readonly property color secondaryText: matugen ? matugen.secondaryText : "#101017"
readonly property color secondaryContainer: matugen ? matugen.secondaryContainer : "#1E3038"
readonly property color secondaryContainerText: matugen ? matugen.secondaryContainerText : "#B8C3E5"

// Tertiary - additional accent
readonly property color tertiary: matugen ? matugen.tertiary : "#9E82D5"
readonly property color tertiaryText: matugen ? matugen.tertiaryText : "#101017"

// Error
readonly property color error: matugen ? matugen.error : "#D9687D"
readonly property color errorText: matugen ? matugen.errorText : "#101017"
readonly property color errorContainer: matugen ? matugen.errorContainer : "#382229"
readonly property color errorContainerText: matugen ? matugen.errorContainerText : "#B8C3E5"

// Success (non-Material extension)
readonly property color success: matugen ? matugen.success : "#86B257"
readonly property color successText: matugen ? matugen.successText : "#101017"

// Background
readonly property color background: matugen ? matugen.background : "#101017"
readonly property color backgroundText: matugen ? matugen.backgroundText : "#B8C3E5"

// Surface - base for cards, sheets, menus
readonly property color surface: matugen ? matugen.surface : "#191A28"
readonly property color surfaceText: matugen ? matugen.surfaceText : "#B8C3E5"
readonly property color surfaceVariant: matugen ? matugen.surfaceVariant : "#1F2030"
readonly property color surfaceVariantText: matugen ? matugen.surfaceVariantText : "#474E6B"

// Surface containers (elevation tiers)
readonly property color surfaceContainerLowest: matugen ? matugen.surfaceContainerLowest : "#101017"
readonly property color surfaceContainerLow: matugen ? matugen.surfaceContainerLow : "#151621"
readonly property color surfaceContainer: matugen ? matugen.surfaceContainer : "#191A28"
readonly property color surfaceContainerHigh: matugen ? matugen.surfaceContainerHigh : "#1F2030"

// Outline
readonly property color outline: matugen ? matugen.outline : "#474E6B"
readonly property color outlineVariant: matugen ? matugen.outlineVariant : "#303650"

// Inverse colors
readonly property color inverseSurface: matugen ? matugen.inverseSurface : "#B8C3E5"
readonly property color inverseSurfaceText: matugen ? matugen.inverseSurfaceText : "#101017"
readonly property color inversePrimary: matugen ? matugen.inversePrimary : "#82AAFF"

// Component-specific (non-Material)
readonly property color track: matugen ? matugen.track : "#303650"
readonly property color thumb: matugen ? matugen.thumb : "#B8C3E5"
readonly property color disabled: "#474E6B"

	// ========== Dimensions ==========

	// UI scale: automatic based on display DPI, clamped to reasonable range.
	// Edit uiScale to override (e.g., 0.9 to make UI 10% smaller).
	readonly property real uiScale: (Qt.application && Qt.application.primaryScreen && Qt.application.primaryScreen.logicalDotsPerInch)
		? Math.max(0.6, Math.min(1.2, 96 / Qt.application.primaryScreen.logicalDotsPerInch))
		: 1.0

	// Base dimensions are multiplied by uiScale so UI adapts to screen density.
	readonly property int floatingWindowWidth: Math.round(600 * uiScale)
	readonly property int floatingWindowHeight: Math.round(700 * uiScale)
	readonly property int notificationWidth: Math.round(360 * uiScale)

	readonly property int floatingWindowMargin: Math.round(8 * uiScale)
	readonly property int floatingWindowRadius: Math.round(16 * uiScale)
	readonly property int floatingContentPadding: Math.round(24 * uiScale)
	readonly property int cardPadding: Math.round(14 * uiScale)
	readonly property int panelInset: Math.round(12 * uiScale)
	readonly property int listItemPadding: Math.round(12 * uiScale)
	readonly property int searchFieldInset: Math.round(8 * uiScale)
	readonly property int searchFieldLeftPadding: Math.round(24 * uiScale)
	readonly property int searchFieldRightPadding: Math.round(24 * uiScale)
	readonly property int searchFieldCompactRightPadding: Math.round(16 * uiScale)

	readonly property int largeGap: Math.round(16 * uiScale)
	readonly property int mediumGap: Math.round(12 * uiScale)
	readonly property int smallGap: Math.round(8 * uiScale)
	readonly property int listGap: Math.round(6 * uiScale)
	readonly property int tightGap: Math.round(4 * uiScale)
	readonly property int microGap: Math.round(2 * uiScale)

	readonly property int listItemRadius: Math.round(100 * uiScale)
	readonly property int listItemSmallRadius: Math.round(8 * uiScale)
	readonly property int searchFieldHeight: Math.round(56 * uiScale)
	readonly property int searchFieldRadius: Math.round(100 * uiScale)
	readonly property int cardRadius: Math.round(18 * uiScale)
	readonly property int notificationCardRadius: Math.round(16 * uiScale)
	readonly property int notificationCardPadding: Math.round(16 * uiScale)
	readonly property int notificationDismissSize: Math.round(28 * uiScale)
	readonly property int notificationDismissRadius: Math.round(14 * uiScale)
	readonly property int notificationActionHeight: Math.round(32 * uiScale)
	readonly property int sliderTrackHeight: Math.round(8 * uiScale)
	readonly property int sliderTrackRadius: Math.round(4 * uiScale)
	readonly property int sliderHandleSize: Math.round(18 * uiScale)
	readonly property int sliderHandleRadius: Math.round(9 * uiScale)
	readonly property int textFieldLeftPadding: Math.round(5 * uiScale)
	readonly property int barHeight: Math.round(56 * uiScale)
	readonly property int barHorizontalPadding: Math.round(12 * uiScale)
	readonly property int barVerticalPadding: Math.round(10 * uiScale)
	readonly property int barSectionGap: Math.round(6 * uiScale)
	readonly property int barCapsuleHorizontalPadding: Math.round(12 * uiScale)
	readonly property int barCapsuleVerticalPadding: Math.round(3 * uiScale)
	readonly property int barCapsuleRadius: Math.round(19 * uiScale)
	readonly property int barWorkspaceButtonSize: Math.round(24 * uiScale)
	readonly property int barStatusButtonSize: Math.round(26 * uiScale)
	readonly property int barTrayIconSize: Math.round(16 * uiScale)

	// ========== Legacy aliases (backward compat) ==========

	// Floating window
	readonly property color floatingBgPrimary: background
	readonly property color floatingBgSecondary: surface
	readonly property color floatingBgHighlight: surfaceVariant
	readonly property color floatingBorder: outline
	readonly property color floatingTextPrimary: surfaceText
	readonly property color floatingTextMuted: surfaceVariantText
	readonly property color floatingAccent: primaryContainer
	readonly property color floatingAccentBright: primary
	readonly property color floatingSuccess: success
	readonly property color floatingDanger: error

	// Panel
	readonly property color panelBgPrimary: background
	readonly property color panelBgSecondary: surface
	readonly property color panelBgTertiary: surfaceVariant
	readonly property color panelMusicSurface: surfaceContainer
	readonly property color panelBorder: outline
	readonly property color panelDivider: outlineVariant
	readonly property color panelTextPrimary: surfaceText
	readonly property color panelTextMuted: surfaceVariantText
	readonly property color panelAccent: primary
	readonly property color panelAccentSoft: primaryContainer
	readonly property color panelSuccess: success
	readonly property color panelDanger: error
	readonly property color panelTrack: track
	readonly property color panelThumb: thumb
	readonly property color panelOutlineStrong: outline

	// Notification
	readonly property color notificationSurface: surface
	readonly property color notificationSurfaceCritical: errorContainer
	readonly property color notificationOnSurface: surfaceText
	readonly property color notificationOnSurfaceVariant: surfaceVariantText
	readonly property color notificationPrimary: primary
	readonly property color notificationSecondaryContainer: primaryContainer
	readonly property color notificationOnSecondaryContainer: primaryContainerText
	readonly property color notificationError: error
	readonly property color notificationErrorContainer: errorContainer
	readonly property color notificationOutlineVariant: outline

	// Bar
	readonly property color barBgPrimary: background
	readonly property color barCapsule: surface
	readonly property color barCapsuleHover: primaryContainer
	readonly property color barTextPrimary: backgroundText
	readonly property color barTextSecondary: surfaceVariantText
	readonly property color barTextDisabled: disabled
	readonly property color barAccent: primary
	readonly property color barAccentContainer: primaryContainer
	readonly property color barOnAccentContainer: primaryContainerText
	readonly property color barTertiary: tertiary
	readonly property color barError: error
	readonly property color barOnError: errorText
}
