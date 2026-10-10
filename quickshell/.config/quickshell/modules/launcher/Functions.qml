import Quickshell
import Quickshell.Io
import QtQuick

Item {
	id: functions

	property var root: null
	property var input: null
	property var listView: null

	// ─────────────────────────────────────────────
	// Configuration
	// ─────────────────────────────────────────────

	// Change this to the actual location of your emoji JSON.
	property string emojiFilePath:
	Quickshell.env("HOME") + "/.config/quickshell/assets/emojis.json"

	property var emojis: []

	// ─────────────────────────────────────────────
	// Emoji database loader
	// ─────────────────────────────────────────────

	Process {
		id: emojiLoader

		command: ["cat", functions.emojiFilePath]

		running: true

		stdout: StdioCollector {
			onStreamFinished: {
				functions.loadEmojis(text)
			}
		}

		stderr: StdioCollector {
			onStreamFinished: {
				if (text.length > 0)
				console.error(
					"Failed to load emoji database:",
					text
				)
			}
		}
	}

	function loadEmojis(jsonText) {
		try {
			const data = JSON.parse(jsonText)

			if (!data || !Array.isArray(data.emojis)) {
				console.error(
					"Emoji database does not contain an 'emojis' array."
				)

				emojis = []
				return
			}

			emojis = data.emojis

			console.log(
				"Loaded",
				emojis.length,
				"emojis"
			)

		} catch (e) {
			console.error(
				"Failed to parse emoji database:",
				e.message
			)

			emojis = []
		}
	}

	// ─────────────────────────────────────────────
	// Clipboard
	// ─────────────────────────────────────────────

	property string clipboardText: ""

	Process {
		id: clipboardProcess

		command: ["wl-copy", functions.clipboardText]

		onExited: {
			functions.clipboardText = ""
		}
	}

	function copyToClipboard(text) {
		if (!text || text.length === 0)
		return

		clipboardText = text
		clipboardProcess.running = true
	}

	// ─────────────────────────────────────────────
	// Launcher
	// ─────────────────────────────────────────────

	function resetLauncher() {
		root.query = ""
		input.text = ""
		root.closeRequested()
	}

	function focusInput() {
		input.forceActiveFocus()
		input.selectAll()
	}

	function launchSelected() {
		if (listView.currentItem && listView.currentItem.modelData) {
			listView.currentItem.modelData.execute()
			functions.resetLauncher()
		}
	}

	// ─────────────────────────────────────────────
	// Emoji entries
	// ─────────────────────────────────────────────

	function createEmojiEntry(item) {
		const emoji = item.emoji || ""
		const name = item.name || "Unknown emoji"

		const category =
		item.category
		? item.category
		: ""

		const subcategory =
		item.subcategory
		? item.subcategory
		: ""

		let comment = ""

		if (category && subcategory) {
			comment = `${category} • ${subcategory}`
		} else if (category) {
			comment = category
		} else if (subcategory) {
			comment = subcategory
		}

		return {
			name: `${name}`,
			comment: comment,
			icon: "",
			emoji: emoji,

			execute: function() {
				functions.copyToClipboard(emoji)
				functions.resetLauncher()
			}
		}
	}

	// ─────────────────────────────────────────────
	// Emoji search
	// ─────────────────────────────────────────────

	function fuzzyScore(name, search) {
		name = name.toLowerCase()
		search = search.toLowerCase().trim()

		if (!search)
		return 0

		if (name === search)
		return 100

		var index = name.indexOf(search)

		if (index !== -1)
		return 80 - index - name.length * 0.01

		var searchWords = search.split(/\s+/)
		var nameWords = name.split(/\s+/)

		var total = 0

		for (var s = 0; s < searchWords.length; s++) {
			var searchWord = searchWords[s]
			var best = 0

			for (var n = 0; n < nameWords.length; n++) {
				var word = nameWords[n]

				if (word.indexOf(searchWord) === 0) {
					best = Math.max(best, 60)
					continue
				}

				var i = 0
				var j = 0

				while (i < word.length && j < searchWord.length) {
					if (word[i] === searchWord[j])
					j++

					i++
				}

				if (j === searchWord.length) {
					var fuzziness = searchWord.length / word.length

					best = Math.max(best, 30 * fuzziness)
				}
			}

			if (best === 0)
			return 0

			total += best
		}

		return total
	}


	function emojiValues(query) {
		const search = query.trim().toLowerCase()

		if (emojis.length === 0) {
			return [{
				name: "Emoji database unavailable",
				comment: functions.emojiFilePath,
				icon: "dialog-error",

				execute: function() {}
			}]
		}

		if (search === "") {
			return emojis.map(createEmojiEntry)
		}

		const results = emojis
		.map(function(item) {
			const name = item.name
			? item.name.toLowerCase()
			: ""

			const category = item.category
			? item.category.toLowerCase()
			: ""

			const subcategory = item.subcategory
			? item.subcategory.toLowerCase()
			: ""

			const emoji = item.emoji
			? item.emoji.toLowerCase()
			: ""

			const code = Array.isArray(item.code)
			? item.code.join(" ").toLowerCase()
			: ""

			const keywords = Array.isArray(item.keywords)
			? item.keywords.join(" ").toLowerCase()
			: ""

			const nameScore = fuzzyScore(name, search)

			const otherMatch =
			category.includes(search)
			|| subcategory.includes(search)
			|| emoji.includes(search)
			|| code.includes(search)
			|| keywords.includes(search)

			return {
				item: item,
				score: otherMatch ? Math.max(nameScore, 20) : nameScore
			}
		})
		.filter(function(result) {
			return result.score > 0
		})
		.sort(function(a, b) {
			return b.score - a.score
		})
		.map(function(result) {
			return result.item
		})

		if (results.length === 0) {
			return [{
				name: "No emoji found",
				comment: `No results for "${query}"`,
				icon: "edit-find",

				execute: function() {}
			}]
		}

		return results.map(createEmojiEntry)
	}

	// ─────────────────────────────────────────────
	// Calculator
	// ─────────────────────────────────────────────

	function safeMathEval(expr) {
		expr = expr.replace(/\s+/g, "")

		const replacements = {
			sqrt: "Math.sqrt",
			sin: "Math.sin",
			cos: "Math.cos",
			tan: "Math.tan",
			asin: "Math.asin",
			acos: "Math.acos",
			atan: "Math.atan",
			log: "Math.log",
			ln: "Math.log",
			log10: "Math.log10",
			abs: "Math.abs",
			ceil: "Math.ceil",
			floor: "Math.floor",
			round: "Math.round",
			exp: "Math.exp",
			pow: "Math.pow",
			min: "Math.min",
			max: "Math.max",
			pi: "Math.PI",
			e: "Math.E",
		}

		for (const key in replacements) {
			const regex = new RegExp(`\\b${key}\\b`, "gi")
			expr = expr.replace(regex, replacements[key])
		}

		expr = expr.replace(/\^/g, "**")

		return Function(
			`"use strict"; return (${expr})`
		)()
	}

	function parseCommand(cmd) {
		const command = cmd.slice(1).trim()
		const args = command.split(/\s+/)

		if (command !== "") {
			if (args.length > 0) {
				try {
					const expression = args.join(" ")
					const result = safeMathEval(expression)

					let formattedResult

					if (typeof result === "number") {
						if (Number.isInteger(result)) {
							formattedResult = result.toString()
						} else {
							formattedResult =
							parseFloat(
								result.toFixed(10)
							).toString()
						}
					} else {
						formattedResult = result.toString()
					}

					return [{
						name: `Calculate: ${expression}`,
						comment: `Result: ${formattedResult}`,
						icon: "accessories-calculator",

						execute: function() {
							functions.resetLauncher()
						}
					}]

				} catch (e) {
					return [{
						name: "Invalid expression",
						comment: `Error: ${e.message}`,
						icon: "dialog-error",

						execute: function() {}
					}]
				}
			}

			return [{
				name: "Calculator Command",
				comment: "Usage: :<expression>",
				icon: "accessories-calculator",

				execute: function() {}
			}]
		}
	}

	// ─────────────────────────────────────────────
	// Main values
	// ─────────────────────────────────────────────

	function values() {
		const allEntries = [
			...DesktopEntries.applications.values
		]

		const q = root.query.trim().toLowerCase()

		// ─────────────────────────────────────────
		// Calculator
		// ─────────────────────────────────────────

		if (q.startsWith("=")) {
			if (q.length === 1) {
				return [{
					name: "Calculator",
					comment: "Examples: :2+2, :sqrt(16)",
					icon: "accessories-calculator",

					execute: function() {}
				}]
			}

			return parseCommand(q)
		}

		// ─────────────────────────────────────────
		// Emoji picker
		// ─────────────────────────────────────────

		if (q === "emoji" || q.startsWith(":")) {
			const search =
			q === ":"
			? ""
			: q.slice(":".length).trim()

			return emojiValues(search)
		}

		// ─────────────────────────────────────────
		// Applications
		// ─────────────────────────────────────────

		allEntries.sort((a, b) =>
		a.name.localeCompare(b.name)
	)

	if (q === "")
	return allEntries

	const entries = allEntries.filter(entry => {
		return (
			entry.name
			&& entry.name.toLowerCase().includes(q)
		) || (
			entry.exec
			&& entry.exec.toLowerCase().includes(q)
		)
	})

	// ─────────────────────────────────────────
	// URL
	// ─────────────────────────────────────────

	if (entries.length === 0) {
		const urlPattern =
		/^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w\-._~:/?#[\]@!$&'()*+,;=]*)?$/

		if (urlPattern.test(q)) {
			const url =
			q.startsWith("http://")
			|| q.startsWith("https://")
			? q
			: `https://${q}`

			return [{
				name: `Open ${url}`,
				comment: 'Open the URL in your default web browser',
				icon: "internet-web-browser",

				execute: function() {
					Qt.openUrlExternally(url)
					functions.resetLauncher()
				}
			}]
		}

		// ─────────────────────────────────────
		// Web search
		// ─────────────────────────────────────

		return [{
			name: "Search the web",
			comment:
			`No results found for "${root.query}", search the web instead`,
			icon: "internet-web-browser",

			execute: function() {
				const url =
				`https://www.google.com/search?q=${
					encodeURIComponent(root.query)
				}`

				Qt.openUrlExternally(url)
				functions.resetLauncher()
			}
		}]
	}

	return entries
}
}

