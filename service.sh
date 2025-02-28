#!/system/bin/sh
MODDIR=${0%/*}
batteryspoof="$MODDIR/spooftemp"
while [ -z "$(getprop sys.boot_completed)" ]; do
	sleep 1
done

apply() {
	for p in $2; do
		if [ -f "$p" ]; then
			chown root:root "$p"
			chmod 644 "$p"
			echo "$1" >"$p"
			chmod 444 "$p"
		fi
	done
}

list_thermal_services() {
	for rc in /system/etc/init/* /vendor/etc/init/* /odm/etc/init/*; do
		grep -r "^service" "$rc" | awk '{print $2}'
	done | grep thermal
}

list_thermal_proc() {
	ps -e -o comm= | grep thermal
}

for svc in $(list_thermal_services); do
	echo "Stopping $svc"
	stop $svc
done

for proc in $(list_thermal_proc); do
	echo "Freeze $proc"
	kill -SIGSTOP "$(pidof "$proc")"
done

# Stop Thermal Service
for thermalsvcmtk in android.hardware.thermal-service.mediatek android.hardware.thermal@2.0-service.mtk; do
    stop "$thermalsvcmtk"
    pidof "$thermalsvcmtk" | xargs -r kill -SIGSTOP
done

for prop in $(resetprop | grep 'thermal.*running' | awk -F '[][]' '{print $2}'); do
	resetprop $prop stopped
done

# Update thermal-related properties
getprop | grep thermal | awk -F '[][]' '{print $2}' | grep -E "init.svc.|init.svc_" | while read -r prop; do
    case $prop in
        init.svc.*) setprop "$prop" stopped ;;
        init.svc_*) resetprop -n "$prop" "" ;;
    esac
done

# Freeze running thermal processes
for thermalprocess in $(pgrep thermal); do
    kill -SIGSTOP "$thermalprocess"
done

# Disable thermal zones policy
for thermalzone in /sys/class/thermal/thermal_zone*/{mode,policy}; do
    [ -f "$thermalzone" ] && apply "${thermalzone##*/}" | sed 's/mode/disabled/;s/policy/userspace/' > "$thermalzone"
done

if [ -d /proc/ppm ]; then
	for idx in $(cat /proc/ppm/policy_status | grep -E 'PWR_THRO|THERMAL' | awk -F'[][]' '{print $2}'); do
		apply "$idx 0" /proc/ppm/policy_status
	done
fi

for trip_point in /sys/class/thermal/*/trip_point_0_temp; do
	apply 125000 $trip_point
done

if [ -f /sys/devices/virtual/thermal/thermal_message/cpu_limits ]; then
	for i in 0 2 4 6 7; do
		maxfreq="$(cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq)"
		[ "$maxfreq" -gt "0" ] && apply "cpu$i $maxfreq" /sys/devices/virtual/thermal/thermal_message/cpu_limits
	done
fi

if [ -f /proc/driver/thermal/tzcpu ]; then
	therlimit="125"
	thermalval="0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler"
	apply "1 ${therlimit}000 0 mtktscpu-sysrst $thermalval 200" /proc/driver/thermal/tzcpu
	apply "1 ${therlimit}000 0 mtktspmic-sysrst $thermalval 1000" /proc/driver/thermal/tzpmic
	apply "1 ${therlimit}000 0 mtktsbattery-sysrst $thermalval 1000" /proc/driver/thermal/tzbattery
	apply "1 ${therlimit}000 0 mtk-cl-kshutdown00 $thermalval 2000" /proc/driver/thermal/tzpa
	apply "1 ${therlimit}000 0 mtktscharger-sysrst $thermalval 2000" /proc/driver/thermal/tzcharger
	apply "1 ${therlimit}000 0 mtktswmt-sysrst $thermalval 1000" /proc/driver/thermal/tzwmt
	apply "1 ${therlimit}000 0 mtktsAP-sysrst $thermalval 1000" /proc/driver/thermal/tzbts
	apply "1 ${therlimit}000 0 mtk-cl-kshutdown01 $thermalval 1000" /proc/driver/thermal/tzbtsnrpa
	apply "1 ${therlimit}000 0 mtk-cl-kshutdown02 $thermalval 1000" /proc/driver/thermal/tzbtspa
fi

# Disable thermal zones
for thermalzone in /sys/class/thermal/thermal_zone*/{mode,policy}; do
    [ -f "$thermalzone" ] && apply "${thermalzone##*/}" | sed 's/mode/disabled/;s/policy/userspace/' > "$thermalzone"
done

# Hide thermal monitoring by making files inaccessible
find /sys/devices/virtual/thermal -type f -exec chmod 000 {} \;

# Disable thermal stats
cmd thermalservice override-status 0

# Battery Temp Spoof
if [ -f "$batteryspoof" ]; then
    echo "Battery Spoofing Enabled"   
    apply "35" /sys/class/power_supply/battery/temperature
else
    echo "Battery Spoofing Disabled"
fi

# Disable Battery Current Limiter
apply "stop 1" "/proc/mtk_batoc_throttling/battery_oc_protect_stop"