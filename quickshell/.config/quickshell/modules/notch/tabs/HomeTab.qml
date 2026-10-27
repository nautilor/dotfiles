import QtQuick
import qs.config
import qs.services
import qs.components

// The Home dashboard: widgets on a grid. In edit mode they can be dragged, resized, configured and removed.
Item {
	id: root

	readonly property real step: HomeLayout.cellW + HomeLayout.gap
	readonly property real stepY: HomeLayout.cellH + HomeLayout.gap

	// snapped target shown while dragging: {x, y, w, h, valid}
	property var ghost: null
	// widgets displaced by the current drop target: {wid: {x, y}}
	property var moves: ({})

	// Aim the drop target at x,y,w,h. Free space is accepted at once; if something is in the way,
	// holding still for a moment makes the others swap or shuffle aside.
	property var aim: null
	function setTarget(wid, x, y, w, h) {
		const a = root.aim;
		if (a && a.wid === wid && a.x === x && a.y === y && a.w === w && a.h === h)
			return;
		root.aim = { wid: wid, x: x, y: y, w: w, h: h };
		dwell.stop();
		root.moves = ({});
		if (HomeLayout.canPlace(wid, x, y, w, h)) {
			root.ghost = { x: x, y: y, w: w, h: h, valid: true };
		} else {
			root.ghost = { x: x, y: y, w: w, h: h, valid: false };
			dwell.restart();
		}
	}
	function clearTarget() {
		dwell.stop();
		root.aim = null;
		root.ghost = null;
		root.moves = ({});
	}
	function drop() {
		const a = root.aim;
		if (a && root.ghost && root.ghost.valid)
			HomeLayout.commit(a.wid, a.x, a.y, a.w, a.h, root.moves);
		clearTarget();
	}
	Timer {
		id: dwell
		interval: 350
		onTriggered: {
			const a = root.aim;
			if (!a)
				return;
			const p = HomeLayout.plan(a.wid, a.x, a.y, a.w, a.h);
			if (p) {
				root.moves = p.moves;
				root.ghost = { x: a.x, y: a.y, w: a.w, h: a.h, valid: true };
			}
		}
	}

	// the fixed layouts have nothing to edit; they replace the grid
	Loader {
		anchors.fill: parent
		active: !HomeStyles.isGrid
		source: HomeStyles.current.source
	}

	Item {
		id: grid
		visible: HomeStyles.isGrid
		width: HomeLayout.gridW
		height: HomeLayout.gridH
		anchors.horizontalCenter: parent.horizontalCenter

		// empty cells, visible only while editing
		Repeater {
			model: HomeLayout.editing ? HomeLayout.cols * HomeLayout.rows : 0
			Rectangle {
				required property int index
				x: (index % HomeLayout.cols) * root.step
				y: Math.floor(index / HomeLayout.cols) * root.stepY
				width: HomeLayout.cellW
				height: HomeLayout.cellH
				radius: 14
				color: Theme.surfaceContainerLow
				opacity: 0.7
			}
		}

		Repeater {
			model: HomeLayout.items

			Item {
				id: frame
				required property var model
				required property int index

				readonly property var def: WidgetTypes.types[model.type]
				readonly property var cfg: JSON.parse(model.cfgJson)
				readonly property var shift: root.moves[model.wid]
				readonly property real baseX: (shift ? shift.x : model.x) * root.step
				readonly property real baseY: (shift ? shift.y : model.y) * root.stepY
				readonly property real baseW: model.w * HomeLayout.cellW + (model.w - 1) * HomeLayout.gap
				readonly property real baseH: model.h * HomeLayout.cellH + (model.h - 1) * HomeLayout.gap

				property real dx: 0
				property real dy: 0
				property real dw: 0
				property real dh: 0
				property bool active: false

				x: baseX + dx
				y: baseY + dy
				width: baseW + dw
				height: baseH + dh
				z: active ? 10 : 1

				Behavior on x {
					enabled: !frame.active
					NumberAnimation {
						duration: Theme.durMedium
						easing.type: Easing.BezierSpline
						easing.bezierCurve: Theme.emphasized
					}
				}
				Behavior on y {
					enabled: !frame.active
					NumberAnimation {
						duration: Theme.durMedium
						easing.type: Easing.BezierSpline
						easing.bezierCurve: Theme.emphasized
					}
				}
				Behavior on width {
					enabled: !frame.active
					NumberAnimation {
						duration: Theme.durMedium
						easing.type: Easing.BezierSpline
						easing.bezierCurve: Theme.emphasized
					}
				}
				Behavior on height {
					enabled: !frame.active
					NumberAnimation {
						duration: Theme.durMedium
						easing.type: Easing.BezierSpline
						easing.bezierCurve: Theme.emphasized
					}
				}

				Loader {
					id: loader
					anchors.fill: parent
					source: frame.def ? frame.def.source : ""
					opacity: HomeLayout.editing ? 0.55 : 1
					Behavior on opacity {
						NumberAnimation {
							duration: Theme.durShort
						}
					}
				}
				Binding {
					target: loader.item
					property: "cfg"
					value: frame.cfg
					when: loader.item !== null
					restoreMode: Binding.RestoreNone
				}
				Binding {
					target: loader.item
					property: "editing"
					value: HomeLayout.editing
					when: loader.item !== null
					restoreMode: Binding.RestoreNone
				}

				// ---- edit mode overlay ----
				Rectangle {
					visible: HomeLayout.editing
					anchors.fill: parent
					radius: 18
					color: "transparent"
					border.width: frame.active ? 3 : 2
					border.color: frame.active ? Theme.primary : Theme.outline
				}

				// drag to move
				MouseArea {
					id: moveArea
					enabled: HomeLayout.editing
					anchors.fill: parent
					cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
					property point start
					onPressed: mouse => {
						start = mapToItem(grid, mouse.x, mouse.y);
						frame.active = true;
					}
					onPositionChanged: mouse => {
						if (!pressed)
							return;
						const p = mapToItem(grid, mouse.x, mouse.y);
						frame.dx = p.x - start.x;
						frame.dy = p.y - start.y;
						const nx = Math.max(0, Math.min(HomeLayout.cols - frame.model.w, Math.round((frame.baseX + frame.dx) / root.step)));
						const ny = Math.max(0, Math.min(HomeLayout.maxRows - frame.model.h, Math.round((frame.baseY + frame.dy) / root.stepY)));
						root.setTarget(frame.model.wid, nx, ny, frame.model.w, frame.model.h);
					}
					onReleased: {
						root.drop();
						frame.active = false;
						frame.dx = 0;
						frame.dy = 0;
					}
				}

				// remove
				Btn {
					visible: HomeLayout.editing
					icon: "close"
					variant: 3
					iconSize: 14
					implicitWidth: 24
					implicitHeight: 24
					anchors.top: parent.top
					anchors.right: parent.right
					anchors.margins: 4
					onClicked: HomeLayout.remove(frame.model.wid)
				}
				// settings
				Btn {
					visible: HomeLayout.editing && frame.def.schema.length + 2 > 0
					icon: "settings"
					iconSize: 14
					implicitWidth: 24
					implicitHeight: 24
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.margins: 4
					onClicked: HomeLayout.configure(frame.model.wid)
				}

				// drag to resize
				Rectangle {
					visible: HomeLayout.editing
					width: 26
					height: 26
					radius: 13
					color: Theme.primary
					anchors.right: parent.right
					anchors.bottom: parent.bottom
					anchors.margins: 3
					Icon {
						anchors.centerIn: parent
						name: "resize"
						size: 16
						color: Theme.primaryFg
					}
					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.SizeFDiagCursor
						property point start
						onPressed: mouse => {
							start = mapToItem(grid, mouse.x, mouse.y);
							frame.active = true;
						}
						onPositionChanged: mouse => {
							if (!pressed)
								return;
							const p = mapToItem(grid, mouse.x, mouse.y);
							const d = frame.def;
							const nw = Math.max(d.minW, Math.min(d.maxW, Math.round((frame.baseW + (p.x - start.x) + HomeLayout.gap) / root.step)));
							const nh = Math.max(d.minH, Math.min(d.maxH, Math.round((frame.baseH + (p.y - start.y) + HomeLayout.gap) / root.stepY)));
							frame.dw = nw * HomeLayout.cellW + (nw - 1) * HomeLayout.gap - frame.baseW;
							frame.dh = nh * HomeLayout.cellH + (nh - 1) * HomeLayout.gap - frame.baseH;
							root.setTarget(frame.model.wid, frame.model.x, frame.model.y, nw, nh);
						}
						onReleased: {
							root.drop();
							frame.active = false;
							frame.dw = 0;
							frame.dh = 0;
						}
					}
				}
			}
		}

		// drop target preview
		Rectangle {
			visible: root.ghost !== null
			x: root.ghost ? root.ghost.x * root.step : 0
			y: root.ghost ? root.ghost.y * root.stepY : 0
			width: root.ghost ? root.ghost.w * HomeLayout.cellW + (root.ghost.w - 1) * HomeLayout.gap : 0
			height: root.ghost ? root.ghost.h * HomeLayout.cellH + (root.ghost.h - 1) * HomeLayout.gap : 0
			radius: 18
			color: root.ghost && root.ghost.valid ? Qt.alpha(Theme.primary, 0.25) : Qt.alpha(Theme.error, 0.25)
			border.width: 2
			border.color: root.ghost && root.ghost.valid ? Theme.primary : Theme.error
			z: 5
		}
	}

	// ---- overlays ----
	TrayMenu {
		id: menu
		visible: HomeLayout.trayItem !== null && !HomeLayout.editing
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.right: parent.right
		width: parent.width / 2
		z: 20
		trayItem: HomeLayout.trayItem
		onClosed: HomeLayout.trayItem = null
	}

	WidgetAddPanel {
		visible: HomeLayout.editing && HomeLayout.panel === "add"
		anchors.fill: parent
		z: 30
	}

	WidgetConfigPanel {
		visible: HomeLayout.editing && HomeLayout.panel === "config"
		anchors.fill: parent
		z: 30
	}

	// leaving the Home tab ends editing
	Component.onDestruction: {
		HomeLayout.editing = false;
		HomeLayout.panel = "";
		HomeLayout.trayItem = null;
	}
}
