#!/bin/bash
# Proper header for a bash script.
# Cleanup, version 2

# Must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
fi

LOG_DIR="/var/log"

cd "$LOG_DIR" || {
    echo "Error: Cannot change to $LOG_DIR"
    exit 1
}

# Safely clear messages log
truncate -s 0 messages

echo "Log cleanup complete."
exit 0

