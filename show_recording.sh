#!/bin/sh
# Save as /bin/src/scripts/show_recording.sh
# Shows "recording" text on screen while recording

while true; do
    if [ -s "/tmp/screencast.pid" ]; then
        pid=$(cat /tmp/screencast.pid)
        if kill -0 "$pid" 2>/dev/null; then
            # Show "recording" text overlay
            echo "recording" | dzen2 -p -x 960 -y 50 -w 100 -h 30 -bg red -fg white -fn "DejaVu Sans:size=12" &
            DZEN_PID=$!
            
            # Wait while recording
            while [ -s "/tmp/screencast.pid" ] && kill -0 "$pid" 2>/dev/null; do
                sleep 1
                pid=$(cat /tmp/screencast.pid 2>/dev/null || echo "")
            done
            
            # Kill the overlay when recording stops
            kill $DZEN_PID 2>/dev/null
        fi
    fi
    sleep 2
done
