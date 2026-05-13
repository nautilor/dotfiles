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

    readonly property color floatingBgPrimary: "#16161f"
    readonly property color floatingBgSecondary: "#1f2030"
    readonly property color floatingBgHighlight: "#2a2a2a"
    readonly property color floatingBorder: "#3d3d3d"
    readonly property color floatingTextPrimary: "#A9B1D6"
    readonly property color floatingTextMuted: "#C8D3F5"
    readonly property color floatingAccent: "#3B4261"
    readonly property color floatingAccentBright: "#545C7E"
    readonly property color floatingSuccess: "#57e389"
    readonly property color floatingDanger: "#f7768e"

    readonly property color panelBgPrimary: "#16161f"
    readonly property color panelBgSecondary: "#1f2030"
    readonly property color panelBgTertiary: "#26283a"
    readonly property color panelMusicSurface: "#2c2130"
    readonly property color panelBorder: "#3d3d3d"
    readonly property color panelDivider: "#414868"
    readonly property color panelTextPrimary: "#c8d3f5"
    readonly property color panelTextMuted: "#a9b1d6"
    readonly property color panelAccent: "#7aa2f7"
    readonly property color panelAccentSoft: "#3B4261"
    readonly property color panelSuccess: "#57e389"
    readonly property color panelDanger: "#f7768e"
    readonly property color panelTrack: "#3a3f5a"
    readonly property color panelThumb: "#f6f7fb"
    readonly property color panelOutlineStrong: "#61688b"

    readonly property color notificationSurface: "#16161f"
    readonly property color notificationSurfaceCritical: "#3b1f29"
    readonly property color notificationOnSurface: "#c0caf5"
    readonly property color notificationOnSurfaceVariant: "#a9b1d6"
    readonly property color notificationPrimary: "#7aa2f7"
    readonly property color notificationSecondaryContainer: "#1f2030"
    readonly property color notificationOnSecondaryContainer: "#c0caf5"
    readonly property color notificationError: "#f7768e"
    readonly property color notificationErrorContainer: "#3b1f29"
    readonly property color notificationOutlineVariant: "#414868"
}
