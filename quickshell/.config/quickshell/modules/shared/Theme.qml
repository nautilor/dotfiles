import QtQuick

QtObject {
    readonly property int floatingWindowWidth: 500
    readonly property int floatingWindowHeight: 700
    readonly property int controlCenterWidth: 500
    readonly property int controlCenterHeight: 550
    readonly property int notificationWidth: 360

    readonly property int floatingWindowMargin: 8
    readonly property int floatingWindowRadius: 16
    readonly property int controlCenterWindowRadius: 22
    readonly property int floatingContentPadding: 24
    readonly property int controlCenterScrollPadding: 16
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

    readonly property int listItemRadius: 10
    readonly property int searchFieldHeight: 56
    readonly property int searchFieldRadius: 12
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

    readonly property color floatingBgPrimary: "#1c1c1c"
    readonly property color floatingBgSecondary: "#222222"
    readonly property color floatingBgHighlight: "#43492a"
    readonly property color floatingBorder: "#666666"
    readonly property color floatingTextPrimary: "#d7c483"
    readonly property color floatingTextMuted: "#c2c2b0"
    readonly property color floatingAccent: "#43492a"
    readonly property color floatingAccentBright: "#78824b"
    readonly property color floatingSuccess: "#5f875f"
    readonly property color floatingDanger: "#685742"

    readonly property color panelBgPrimary: "#1c1c1c"
    readonly property color panelBgSecondary: "#222222"
    readonly property color panelBgTertiary: "#151515"
    readonly property color panelMusicSurface: "#2f261c"
    readonly property color panelBorder: "#666666"
    readonly property color panelDivider: "#666666"
    readonly property color panelTextPrimary: "#d7c483"
    readonly property color panelTextMuted: "#c2c2b0"
    readonly property color panelAccent: "#78824b"
    readonly property color panelAccentSoft: "#43492a"
    readonly property color panelSuccess: "#5f875f"
    readonly property color panelDanger: "#685742"
    readonly property color panelTrack: "#43492a"
    readonly property color panelThumb: "#d7c483"
    readonly property color panelOutlineStrong: "#666666"

    readonly property color notificationSurface: "#1c1c1c"
    readonly property color notificationSurfaceCritical: "#3b312b"
    readonly property color notificationOnSurface: "#d7c483"
    readonly property color notificationOnSurfaceVariant: "#c2c2b0"
    readonly property color notificationPrimary: "#78824b"
    readonly property color notificationSecondaryContainer: "#222222"
    readonly property color notificationOnSecondaryContainer: "#d7c483"
    readonly property color notificationError: "#685742"
    readonly property color notificationErrorContainer: "#3b312b"
    readonly property color notificationOutlineVariant: "#666666"
}
