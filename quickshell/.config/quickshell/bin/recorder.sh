#!/usr/bin/env bash
#
# Toggle screen recording via wf-recorder.
#
set -euo pipefail

readonly OUTPUT_DIR="${HOME}/Videos/Recordings"
readonly PID_FILE="/tmp/recorder_pid"
readonly FILE_PATH_RECORD="/tmp/recorder_output_path"
readonly FFMPEG_LOG="/tmp/ffmpeg_recording.log"

start_recording() {
	mkdir -p "$OUTPUT_DIR"

	local timestamp output_file
	timestamp=$(date +"%Y%m%d_%H%M%S")
	output_file="${OUTPUT_DIR}/recording_${timestamp}.mp4"

	wf-recorder --audio="bluez_output.90:7A:58:EB:28:A2.monitor" -f "$output_file" &>"$FFMPEG_LOG" &
	echo $! > "$PID_FILE"
	echo "$output_file" > "$FILE_PATH_RECORD"

	notify-send -i media-record-symbolic "Recording Started" "You are now recording"
	echo "Recording started: $output_file"
}

stop_recording() {
	if [[ ! -f "$PID_FILE" ]]; then
		echo "No recording in progress."
		return
	fi

	local pid output_file action
	pid=$(cat "$PID_FILE")
	output_file=$(cat "$FILE_PATH_RECORD")

	kill "$pid"
	rm -f "$PID_FILE" "$FILE_PATH_RECORD"
	echo "Recording stopped."

	action=$(notify-send -i media-record-symbolic "Recording Stopped" "Saved to: ${output_file}" \
		-a "Recording Stopped" \
		--action="open_folder=Open Folder")

	if [[ "$action" == "open_folder" ]]; then
		xdg-open "$OUTPUT_DIR"
	fi
}

if [[ -f "$PID_FILE" ]]; then
	stop_recording
else
	start_recording
fi
