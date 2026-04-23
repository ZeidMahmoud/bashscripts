#!/bin/sh
tmpPID="/tmp/screencast.pid"
pauseFile="/tmp/screencast.paused"
outputDir="$HOME/screencast"
timeStamp=$(date '+%Y%m%d_%H%M%S')
outputfile="$outputDir/$timeStamp.mov"

mkdir -p "$outputDir"

if [ -s "$tmpPID" ]; then
    if [ -f "$pauseFile" ]; then
        # Resume
        kill -CONT $(cat "$tmpPID")
        rm "$pauseFile"
        echo "Recording resumed"
    else
        # Stop
        kill $(cat "$tmpPID") 2>/dev/null
        rm -f "$tmpPID" "$pauseFile"
        echo "Recording stopped and saved"
    fi
else
    # Start
    echo "Starting recording..."
    ffmpeg -framerate 24 -video_size 1920x1080 -f x11grab -i :0 -f pulse -i default \
    -vcodec libx264 -preset fast -threads 0 -acodec pcm_s32le -ac 1 -ab 320k "$outputfile" &
    echo $! > "$tmpPID"
    echo "Recording started: $outputfile"
fi
pkill -RTMIN+10 slstatus 2>/dev/null
