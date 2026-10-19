pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
	id: root

	readonly property var players: Mpris.players.values
	readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
	readonly property bool playing: player !== null && player.isPlaying
}
