#!/system/bin/sh
MODDIR=${0%/*}

resetprop -n -v debug.thermal.throttle.support no

Zenith >/dev/null 2>&1
