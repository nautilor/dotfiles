#!/usr/bin/env bash

OUTPUT_DIR="$HOME/Videos/Recordings"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="$OUTPUT_DIR/recording_$TIMESTAMP.mkv"
PID_FILE="/tmp/recorder_pid"
FFMPEG_LOG="/tmp/ffmpeg_recording.log"

start_recording() {
		mkdir -p "$OUTPUT_DIR"
		wf-recorder --audio="bluez_output.90:7A:58:EB:28:A2.monitor" -f "$OUTPUT_FILE" &
		echo $! > "$PID_FILE"
		notify-send -i media-record-symbolic "Recording Started" "You are now recording"
		echo "Recording started: $OUTPUT_FILE"
}

stop_recording() {
		if [ -f "$PID_FILE" ]; then
				PID=$(cat "$PID_FILE")
				kill "$PID"
				rm "$PID_FILE"
				echo "Recording stopped."
				action=$(notify-send -i media-record-symbolic "Recording Stopped" "Saved to: $OUTPUT_FILE" \
				-a "Recording Stopped" \
				--action="open_folder=Open Folder")
				if [ "$action" = "open_folder" ]; then
					nautilus "$OUTPUT_DIR"
				fi
		else
				echo "No recording in progress."
		fi
}

if [ -f "$PID_FILE" ]; then
		stop_recording
else
		start_recording
fi

