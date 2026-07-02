import QtQuick

QtObject {
	// Load custom colors if exist, else use defaults
	property QtObject customColors: {
		var component = Qt.createComponent(Qt.resolvedUrl("CustomColors.qml"));
		if (component.status === Component.Ready) {
			return component.createObject(this);
		}
		return null;
	}
	
	// ========== Material Design 3 Color System ==========
	
	// Primary - main brand color
	readonly property color primary: customColors ? customColors.primary : "#E290B2"
	readonly property color primaryText: customColors ? customColors.primaryText : "#FAEEF3"
	readonly property color primaryContainer: customColors ? customColors.primaryContainer : "#302833"
	readonly property color primaryContainerText: customColors ? customColors.primaryContainerText : "#FAEEF3"
	
	// Secondary - complementary accent
	readonly property color secondary: customColors ? customColors.secondary : "#C4B2BD"
	readonly property color secondaryText: customColors ? customColors.secondaryText : "#111014"
	readonly property color secondaryContainer: customColors ? customColors.secondaryContainer : "#241F29"
	readonly property color secondaryContainerText: customColors ? customColors.secondaryContainerText : "#F3E8EE"
	
	// Tertiary - additional accent
	readonly property color tertiary: customColors ? customColors.tertiary : "#B79AD9"
	readonly property color tertiaryText: customColors ? customColors.tertiaryText : "#111014"
	
	// Error
	readonly property color error: customColors ? customColors.error : "#D97C95"
	readonly property color errorText: customColors ? customColors.errorText : "#FFE7EC"
	readonly property color errorContainer: customColors ? customColors.errorContainer : "#3A222B"
	readonly property color errorContainerText: customColors ? customColors.errorContainerText : "#FAEEF3"
	
	// Success (non-Material extension)
	readonly property color success: customColors ? customColors.success : "#9EB58A"
	readonly property color successText: customColors ? customColors.successText : "#111014"
	
	// Background
	readonly property color background: customColors ? customColors.background : "#111014"
	readonly property color backgroundText: customColors ? customColors.backgroundText : "#F3E8EE"
	
	// Surface - base for cards, sheets, menus
	readonly property color surface: customColors ? customColors.surface : "#1A171E"
	readonly property color surfaceText: customColors ? customColors.surfaceText : "#F3E8EE"
	readonly property color surfaceVariant: customColors ? customColors.surfaceVariant : "#241F29"
	readonly property color surfaceVariantText: customColors ? customColors.surfaceVariantText : "#C4B2BD"
	
	// Surface containers (elevation tiers)
	readonly property color surfaceContainerLowest: customColors ? customColors.surfaceContainerLowest : "#111014"
	readonly property color surfaceContainerLow: customColors ? customColors.surfaceContainerLow : "#1A171E"
	readonly property color surfaceContainer: customColors ? customColors.surfaceContainer : "#201B24"
	readonly property color surfaceContainerHigh: customColors ? customColors.surfaceContainerHigh : "#241F29"
	
	// Outline
	readonly property color outline: customColors ? customColors.outline : "#4B424F"
	readonly property color outlineVariant: customColors ? customColors.outlineVariant : "#342D38"
	
	// Inverse colors
	readonly property color inverseSurface: customColors ? customColors.inverseSurface : "#F3E8EE"
	readonly property color inverseSurfaceText: customColors ? customColors.inverseSurfaceText : "#111014"
	readonly property color inversePrimary: customColors ? customColors.inversePrimary : "#302833"
	
	// Component-specific (non-Material)
	readonly property color track: customColors ? customColors.track : "#454048"
	readonly property color thumb: customColors ? customColors.thumb : "#E8D7DF"
	readonly property color disabled: "#817682"
	
	// ========== Dimensions ==========
	
	readonly property int floatingWindowWidth: 700
	readonly property int floatingWindowHeight: 400
	readonly property int notificationWidth: 360

	readonly property int floatingWindowMargin: 8
	readonly property int floatingWindowRadius: 16
	readonly property int floatingContentPadding: 24
	readonly property int cardPadding: 14
	readonly property int panelInset: 12
	readonly property int listItemPadding: 12
	readonly property int searchFieldInset: 8
	readonly property int searchFieldLeftPadding: 24
	readonly property int searchFieldRightPadding: 24
	readonly property int searchFieldCompactRightPadding: 16

	readonly property int largeGap: 16
	readonly property int mediumGap: 12
	readonly property int smallGap: 8
	readonly property int listGap: 6
	readonly property int tightGap: 4
	readonly property int microGap: 2

	readonly property int listItemRadius: 100
	readonly property int listItemSmallRadius: 8
	readonly property int searchFieldHeight: 56
	readonly property int searchFieldRadius: 100
	readonly property int cardRadius: 18
	readonly property int notificationCardRadius: 16
	readonly property int notificationCardPadding: 16
	readonly property int notificationDismissSize: 28
	readonly property int notificationDismissRadius: 14
	readonly property int notificationActionHeight: 32
	readonly property int sliderTrackHeight: 8
	readonly property int sliderTrackRadius: 4
	readonly property int sliderHandleSize: 18
	readonly property int sliderHandleRadius: 9
	readonly property int textFieldLeftPadding: 5
	readonly property int barHeight: 56
	readonly property int barHorizontalPadding: 12
	readonly property int barVerticalPadding: 10
	readonly property int barSectionGap: 6
	readonly property int barCapsuleHorizontalPadding: 12
	readonly property int barCapsuleVerticalPadding: 3
	readonly property int barCapsuleRadius: 19
	readonly property int barWorkspaceButtonSize: 24
	readonly property int barStatusButtonSize: 26
	readonly property int barTrayIconSize: 16

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
