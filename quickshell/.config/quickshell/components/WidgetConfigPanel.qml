import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Settings of one Home widget: size plus whatever its type offers.
Rectangle {
	id: root

	readonly property int idx: {
		HomeLayout.revision;
		return HomeLayout.indexOf(HomeLayout.selected);
	}
	readonly property var item: {
		HomeLayout.revision;
		return idx >= 0 ? HomeLayout.items.get(idx) : null;
	}
	readonly property var def: item ? WidgetTypes.types[item.type] : null
	readonly property var cfg: item ? WidgetTypes.resolve(item.type, JSON.parse(item.cfgJson)) : ({})
	property string error: ""

	radius: Theme.radiusLarge
	color: Theme.surfaceContainerHigh

	function resizeTo(w, h) {
		const ok = HomeLayout.place(item.wid, item.x, item.y, Math.max(def.minW, Math.min(def.maxW, w)), Math.max(def.minH, Math.min(def.maxH, h)));
		error = ok ? "" : "No room to resize here.";
	}

	MouseArea {
		anchors.fill: parent
	}

	component Stepper: Row {
		id: stepper
		property int value
		property int min: 1
		property int max: 99
		property int step: 1
		signal changed(int v)
		spacing: 6
		Btn {
			icon: "remove"
			implicitWidth: 34
			implicitHeight: 34
			iconSize: 18
			onClicked: stepper.changed(Math.max(stepper.min, stepper.value - stepper.step))
		}
		Txt {
			width: 44
			height: 34
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			text: stepper.value
			font.weight: Font.Bold
		}
		Btn {
			icon: "add"
			implicitWidth: 34
			implicitHeight: 34
			iconSize: 18
			onClicked: stepper.changed(Math.min(stepper.max, stepper.value + stepper.step))
		}
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 12
		spacing: 8

		RowLayout {
			Layout.fillWidth: true
			Icon {
				name: root.def ? root.def.icon : ""
				size: 22
				fill: 1
				color: Theme.primary
			}
			Txt {
				text: root.def ? root.def.title : ""
				font.pixelSize: 17
				font.weight: Font.Bold
				Layout.fillWidth: true
			}
			Txt {
				visible: root.error !== ""
				text: root.error
				color: Theme.error
				font.pixelSize: 12
			}
			Btn {
				icon: "delete"
				label: "Remove"
				variant: 3
				implicitHeight: 34
				onClicked: HomeLayout.remove(HomeLayout.selected)
			}
			Btn {
				icon: "check"
				label: "Done"
				variant: 1
				implicitHeight: 34
				onClicked: HomeLayout.panel = ""
			}
		}

		Flickable {
			Layout.fillWidth: true
			Layout.fillHeight: true
			contentHeight: form.implicitHeight + 8
			clip: true
			boundsBehavior: Flickable.StopAtBounds

			ColumnLayout {
				id: form
				width: parent.width - 8
				spacing: 8

				SettingRow {
					visible: root.def !== null
					title: "Width"
					subtitle: root.def ? "columns, " + root.def.minW + " to " + root.def.maxW : ""
					Stepper {
						value: root.item ? root.item.w : 1
						min: root.def ? root.def.minW : 1
						max: root.def ? root.def.maxW : 1
						onChanged: v => root.resizeTo(v, root.item.h)
					}
				}
				SettingRow {
					visible: root.def !== null
					title: "Height"
					subtitle: root.def ? "rows, " + root.def.minH + " to " + root.def.maxH : ""
					Stepper {
						value: root.item ? root.item.h : 1
						min: root.def ? root.def.minH : 1
						max: root.def ? root.def.maxH : 1
						onChanged: v => root.resizeTo(root.item.w, v)
					}
				}

				Repeater {
					model: root.def ? root.def.schema : []

					SettingRow {
						id: row
						required property var modelData
						readonly property var field: modelData
						readonly property var current: root.cfg[field.key]
						title: field.label

						Field {
							visible: row.field.kind === "text"
							implicitWidth: 320
							implicitHeight: 38
							color: Theme.surfaceContainerHighest
							placeholder: row.field.placeholder || ""
							Component.onCompleted: text = row.current ?? ""
							onEdited: v => HomeLayout.setConfig(HomeLayout.selected, row.field.key, v)
						}

						Switch {
							visible: row.field.kind === "bool"
							checked: !!row.current
							onToggled: v => HomeLayout.setConfig(HomeLayout.selected, row.field.key, v)
						}

						Flow {
							visible: row.field.kind === "choice"
							Layout.maximumWidth: 380
							spacing: 6
							Repeater {
								model: row.field.kind === "choice" ? row.field.options : []
								Btn {
									required property string modelData
									implicitHeight: 34
									label: modelData
									toggleable: true
									toggled: row.current === modelData
									toggledRadius: 14
									onClicked: HomeLayout.setConfig(HomeLayout.selected, row.field.key, modelData)
								}
							}
						}

						Stepper {
							visible: row.field.kind === "number"
							value: Number(row.current) || 0
							min: row.field.min ?? 0
							max: row.field.max ?? 999
							step: row.field.step ?? 1
							onChanged: v => HomeLayout.setConfig(HomeLayout.selected, row.field.key, v)
						}

						Flow {
							visible: row.field.kind === "icon"
							Layout.maximumWidth: 420
							spacing: 4
							Repeater {
								model: row.field.kind === "icon" ? WidgetTypes.iconChoices : []
								Btn {
									required property string modelData
									implicitWidth: 36
									implicitHeight: 36
									icon: modelData
									iconSize: 20
									toggleable: true
									toggled: row.current === modelData
									toggledRadius: 12
									onClicked: HomeLayout.setConfig(HomeLayout.selected, row.field.key, modelData)
								}
							}
						}
					}
				}
			}
		}
	}
}
