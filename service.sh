while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 1
done

resetprop -n -v debug.thermal.throttle.support no
resetprop -n ro.vendor.mtk_thermal_2_0 0
resetprop -n persist.thermal_config.mitigation 0
resetprop -n ro.mtk_thermal_monitor.enabled false

Zenith >/dev/null 2>&1