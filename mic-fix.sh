#!/bin/bash
hda-verb /dev/snd/hwC0D0 0x19 SET_PIN_WIDGET_CONTROL 0x24
hda-verb /dev/snd/hwC0D0 0x19 SET_AMP_GAIN_MUTE 0xb080
amixer set "Capture" unmute cap 80%
amixer set "Mic Boost" unmute 70%
amixer set "Internal Mic Boost" unmute 60%
