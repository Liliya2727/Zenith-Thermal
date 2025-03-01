#!/system/bin/sh
LOGFILE="/data/local/tmp/Zenith.log"
TempUnSupport="/data/adb/modules/ZenithThermal/TempUnSupport"
BATTERY_SPOOF="$MODDIR/spooftemp"

log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOGFILE"
}

# Log first message before deleting the log file
log "INFO" "Starting ZenithThermal script..."
rm -f "$LOGFILE"

# Wait for boot to complete (with timeout)
log "INFO" "Waiting for boot to complete..."
BOOT_TIMEOUT=60  # Max wait time in seconds
elapsed=0
while [ -z "$(getprop sys.boot_completed)" ] && [ "$elapsed" -lt "$BOOT_TIMEOUT" ]; do
    sleep 2
    elapsed=$((elapsed + 2))
done

if [ -z "$(getprop sys.boot_completed)" ]; then
    log "ERROR" "Boot did not complete within $BOOT_TIMEOUT seconds. Exiting!"
    exit 1
fi

log "INFO" "Boot completed!"

thermal() {
    find /system/etc/init /vendor/etc/init /odm/etc/init -type f 2>/dev/null | xargs grep -h "^service" | awk '{print $2}' | grep thermal
}


propfile() {
    log "INFO" "Resetting thermal-related properties..."

    # List of properties to reset
    while read -r key value; do
        log "INFO" "Setting $key to $value..."
        resetprop -n "$key" "$value"

        if [ "$(resetprop "$key")" = "$value" ]; then
            log "INFO" "Successfully set $key to $value"
        else
            log "ERROR" "Failed to set $key to $value!"
        fi
    done <<EOF
debug.thermal.throttle.support no
ro.vendor.mtk_thermal_2_0 0
persist.thermal_config.mitigation 0
ro.mtk_thermal_monitor.enabled false
ro.vendor.tran.hbm.thermal.temp.clr 59000
ro.vendor.tran.hbm.thermal.temp.trig 59000
vendor.thermal.link_ready 0
dalvik.vm.dexopt.thermal-cutoff 9999
persist.vendor.thermal.engine.enable 0
persist.vendor.thermal.config 0
EOF

    # Check and stop thermal services
    if [ -f /vendor/bin/hw/android.hardware.thermal-service.mediatek ]; then
        log "INFO" "Stopping android.hardware.thermal-service.mediatek..."
        resetprop -n init.svc.android.hardware.thermal-service.mediatek stopped

        if [ "$(resetprop init.svc.android.hardware.thermal-service.mediatek)" = "stopped" ]; then
            log "INFO" "Successfully stopped android.hardware.thermal-service.mediatek"
        else
            log "ERROR" "Failed to stop android.hardware.thermal-service.mediatek!"
        fi
    else
        log "WARNING" "android.hardware.thermal-service.mediatek binary not found!"
    fi

    if [ -f /vendor/bin/hw/android.hardware.thermal@2.0-service.mtk ]; then
        log "INFO" "Stopping android.hardware.thermal@2.0-service.mtk..."
        resetprop -n init.svc.android.hardware.thermal@2.0-service.mtk stopped

        if [ "$(resetprop init.svc.android.hardware.thermal@2.0-service.mtk)" = "stopped" ]; then
            log "INFO" "Successfully stopped android.hardware.thermal@2.0-service.mtk"
        else
            log "ERROR" "Failed to stop android.hardware.thermal@2.0-service.mtk!"
        fi
    else
        log "WARNING" "android.hardware.thermal@2.0-service.mtk binary not found!"
    fi

    log "INFO" "Thermal property reset process completed."
}

propfile
# Disable Battery Overcharge Thermal Throttling
if [ -f "/proc/mtk_batoc_throttling/battery_oc_protect_stop" ]; then
    log "INFO" "Disabling Battery Overcharge Thermal Throttling..."
    echo "stop 1" > /proc/mtk_batoc_throttling/battery_oc_protect_stop
else
    log "ERROR" "Battery Overcharge Thermal Throttling file not found!"
fi

# Set max CPU temperature trip point
for trip_point in /sys/class/thermal/*/trip_point_0_temp; do
    if [ -f "$trip_point" ]; then
        log "INFO" "Setting max CPU temperature trip point to 160°C on $trip_point"
        echo 160000 > "$trip_point"
    else
        log "ERROR" "Trip point file $trip_point not found!"
    fi
done

log "INFO" "Stopping thermal services..."
stop thermal_core
stop vendor.thermal-hal-2-0.mtk

# Check if thermal services stopped successfully
if pgrep -f "thermal" > /dev/null; then
    log "WARNING" "Failed to stop some thermal services!"
else
    log "INFO" "All thermal services stopped successfully."
fi

# Disable hardware thermal shutdown mechanisms
if [ -f /proc/driver/thermal/tzcpu ]; then
    THERMAL_LIMIT="125"
    THERMAL_VAL="0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler"
    
    log "INFO" "Disabling hardware thermal shutdown mechanisms..."
    echo "1 ${THERMAL_LIMIT}000 0 mtktscpu-sysrst $THERMAL_VAL 200" > /proc/driver/thermal/tzcpu
else
    log "ERROR" "/proc/driver/thermal/tzcpu not found!"
fi

# Stop all detected thermal services
for svc in $(thermal); do
    log "INFO" "Stopping $svc..."
    stop "$svc"
done

# Verify if services were stopped
if pgrep -f "thermal" > /dev/null; then
    log "ERROR" "Some thermal services are still running!"
else
    log "INFO" "All thermal services stopped successfully."
fi

# Freeze running thermal processes
for thermalpr in $(pgrep thermal); do
    log "INFO" "Freezing thermal process PID $thermalpr..."
    kill -SIGSTOP "$thermalpr"
done

# Reset init.svc_ properties
for thermalinit in $(getprop | awk -F '[][]' '/init\.svc_/ {print $2}'); do
    if [ -n "$thermalinit" ]; then
        log "INFO" "Resetting property: $thermalinit"
        resetprop -n "$thermalinit" ""
    fi
done

# Stop specific services and freeze their processes
for kill in android.hardware.thermal-service.mediatek android.hardware.thermal@2.0-service.mtk; do
    log "INFO" "Checking if $kill service exists..."

    if getprop | grep -q "$kill"; then
        log "INFO" "Stopping $kill..."
        if stop "$kill"; then
            log "INFO" "$kill stopped successfully."
        else
            log "ERROR" "Failed to stop $kill!"
        fi

        thermalhwsvc=$(pidof "$kill")
        if [ -n "$thermalhwsvc" ]; then
            log "INFO" "Killing process PID $thermalhwsvc..."
            if kill -9 "$thermalhwsvc"; then
                log "INFO" "Successfully killed $kill (PID: $thermalhwsvc)."
            else
                log "ERROR" "Failed to kill $kill (PID: $thermalhwsvc)!"
            fi
        else
            log "WARNING" "No running process found for $kill, skipping kill step."
        fi
    else
        log "WARNING" "$kill service is not found on the system, skipping."
    fi
done

# Check and disable thermal binaries using alternative methods
for kill2 in /vendor/bin/hw/android.hardware.thermal-service.mediatek /vendor/bin/hw/android.hardware.thermal@2.0-service.mtk; do
    if [ -f "$kill2" ]; then
        log "INFO" "Attempting to disable $kill2..."
        
        # Try renaming the binary
        mv "$kill2" "$kill2.bak" && log "INFO" "Renamed $kill2 to $kill2.bak to prevent execution."

        # Try overwriting with an empty file
        echo "" > "$kill2" && log "INFO" "Overwritten $kill2 with an empty file."

        # Try setting restrictive permissions
        chmod 000 "$kill2" && log "INFO" "Permissions set to 000 (no access) for $kill2."

    else
        log "ERROR" "$kill2 binary not found! Skipping..."
    fi
done

# Reset thermal properties
for thermalprop in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc.); do
    log "INFO" "Resetting thermal property: $thermalprop"
    resetprop "$thermalprop" stopped
done

# Disable thermal zones
if [ -d "/sys/class/thermal" ]; then
    chmod 644 /sys/class/thermal/thermal_zone*/mode
    for thermalzone in /sys/class/thermal/thermal_zone*/mode; do
        log "INFO" "Disabling thermal zone: $thermalzone"
        [ -f "$thermalzone" ] && echo "disabled" > "$thermalzone"
    done
else
    log "ERROR" "/sys/class/thermal directory not found!"
fi

# Hide and disable monitoring of thermal zones
if [ -d "/sys/devices/virtual/thermal" ]; then
    log "INFO" "Hiding thermal zone monitoring..."
    find /sys/devices/virtual/thermal -type f -exec chmod 000 {} +
else
    log "ERROR" "/sys/devices/virtual/thermal directory not found!"
fi

# Disable Thermal Stats
cmd thermalservice override-status 0

# Battery Temp Spoofing
tspf() {
sleep 1
if [ -f "$BATTERY_SPOOF" ]; then
    log "INFO" "Battery Spoofing Enabled"
    echo "35" > /sys/class/power_supply/battery/temperature
else
    log "INFO" "Battery Spoofing Disabled"
fi
}

log "INFO" "Thermal control script execution completed!"

tspf