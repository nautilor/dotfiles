import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
	id: functions

	property var root: null
	property var input: null
	property var listView: null

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
		return Function(`"use strict"; return (${expr})`)()
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
						if (Number.isInteger(result))
							formattedResult = result.toString()
						else
							formattedResult = parseFloat(result.toFixed(10)).toString()
					} else {
						formattedResult = result.toString()
					}

					return [{
						name: `Calculate: ${expression}`,
						comment: `Result: ${formattedResult}`,
						icon: "accessories-calculator",
						execute: function() {
							functions.resetLauncher()
						},
					}]
				} catch (e) {
					return [{
						name: "Invalid expression",
						comment: `Error: ${e.message}`,
						icon: "dialog-error",
						execute: function() {},
					}]
				}
			}

			return [{
				name: "Calculator Command",
				comment: "Usage: :<expression>",
				icon: "accessories-calculator",
				execute: function() {},
			}]
		}
	}

	function values() {
		const allEntries = [...DesktopEntries.applications.values]
		const q = root.query.trim().toLowerCase()

		if (q.startsWith(":")) {
			if (q.length === 1) {
				return [{
					name: "Calculator",
					comment: "Examples: :2+2, :sqrt(16)",
					icon: "accessories-calculator",
					execute: function() {},
				}]
			}

			return parseCommand(q)
		}

		allEntries.sort((a, b) => a.name.localeCompare(b.name))

		if (q === "")
			return allEntries

		const entries = allEntries.filter(entry => {
			return (entry.name && entry.name.toLowerCase().includes(q))
			|| (entry.exec && entry.exec.toLowerCase().includes(q))
		})

		if (entries.length === 0) {
			const urlPattern = /^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w\-._~:/?#[\]@!$&'()*+,;=]*)?$/
			if (urlPattern.test(q)) {
				const url = q.startsWith("http://") || q.startsWith("https://") ? q : `https://${q}`
				return [{
					name: `Open ${url}`,
					comment: `Open ${url} with default application`,
					icon: "document-open",
					execute: function() {
						Qt.openUrlExternally(url)
						functions.resetLauncher()
					},
				}]
			}

			return [{
				name: "Search the web",
				comment: `No results found for "${root.query}", search the web instead`,
				icon: "internet-web-browser",
				execute: function() {
					const url = `https://www.google.com/search?q=${encodeURIComponent(root.query)}`
					Qt.openUrlExternally(url)
					functions.resetLauncher()
				},
			}]
		}

		return entries
	}
}
