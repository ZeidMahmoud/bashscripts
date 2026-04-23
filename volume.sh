#!/bin/sh
/usr/bin/amixer get Master | awk -F'[][]' '/%/ { print $2; exit }'
