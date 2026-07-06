import QtQuick

QtObject {	
	property color primary: "{{colors.primary.default.hex}}"
	property color primaryText: "{{colors.on_primary.default.hex}}"
	property color primaryContainer: "{{colors.primary_container.default.hex}}"
	property color primaryContainerText: "{{colors.on_primary_container.default.hex}}"
			
	property color secondary: "{{colors.secondary.default.hex}}"
	property color secondaryText: "{{colors.on_secondary.default.hex}}"
	property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
	property color secondaryContainerText: "{{colors.on_secondary_container.default.hex}}"
			
	property color tertiary: "{{colors.tertiary.default.hex}}"
	property color tertiaryText: "{{colors.on_tertiary.default.hex}}"

	property color error: "{{colors.error.default.hex}}"
	property color errorText: "{{colors.on_error.default.hex}}"
	property color errorContainer: "{{colors.error_container.default.hex}}"
	property color errorContainerText: "{{colors.on_error_container.default.hex}}"

	property color success: "{{colors.tertiary.default.hex}}"
	property color successText: "{{colors.on_tertiary.default.hex}}"

	property color background: "{{colors.background.default.hex}}"
	property color backgroundText: "{{colors.on_background.default.hex}}"

	property color surface: "{{colors.surface_container.default.hex}}"
	property color surfaceText: "{{colors.on_surface.default.hex}}"

	property color surfaceVariant: "{{colors.surface_container.default.hex}}"
	property color surfaceVariantText: "{{colors.on_surface_variant.default.hex}}"

	property color surfaceContainerLowest: "{{colors.surface_container_lowest.default.hex}}"
	property color surfaceContainerLow: "{{colors.surface_container_low.default.hex}}"
	property color surfaceContainer: "{{colors.surface_container.default.hex}}"
	property color surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"

	property color outline: "{{colors.outline.default.hex}}"
	property color outlineVariant: "{{colors.outline_variant.default.hex}}"

	property color inverseSurface: "{{colors.inverse_surface.default.hex}}"
	property color inverseSurfaceText: "{{colors.inverse_on_surface.default.hex}}"
	property color inversePrimary: "{{colors.inverse_primary.default.hex}}"

	property color track: "{{colors.surface_variant.default.hex}}"
	property color thumb: "{{colors.on_surface.default.hex}}"
}
