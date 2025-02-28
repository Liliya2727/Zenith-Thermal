#!/system/bin/sh

resetprop -n -v debug.thermal.throttle.support no
resetprop -n ro.vendor.mtk_thermal_2_0 0
resetprop -n persist.thermal_config.mitigation 0
resetprop -n ro.mtk_thermal_monitor.enabled false