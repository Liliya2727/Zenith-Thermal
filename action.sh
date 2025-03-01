#!/system/bin/sh
MODDIR=${0%/*}
BATTERY_SPOOF="$MODDIR/spooftemp"
MODULE_PROP="/data/adb/modules/ZenithThermal/module.prop"
# Function to print messages with delay
zenith_print() {
    echo ""
    echo "================================="
    echo "        ZENITH THERMAL          "
    echo "================================="
    echo ""
    sleep 1
}

# ================================
#      Toggle Temp Spoof
# ================================
zenith_print

if [ -f "$BATTERY_SPOOF" ]; then
    echo "Temp Spoof Status: Enabled"
    sleep 2
    echo "Disabling Temp Spoof..."
    sleep 3
    rm -f "$BATTERY_SPOOF"
    echo "Temp Spoof is now Disabled."
    if [ -f "$MODULE_PROP" ]; then
        sed -i "s|^description=.*|description=Disable thermal for mtk D8050/D8020! Should work on other MTK devices • Tempspoof Status: Disabled!❌|" "$MODULE_PROP"
    else
        echo "Error: module.prop not found!" >&2
    fi
else
    echo "Temp Spoof Status: Disabled"
    sleep 2
    echo "Enabling Temp Spoof..."
    sleep 3
    touch "$BATTERY_SPOOF"
    echo "Temp Spoof is now Enabled."
    if [ -f "$MODULE_PROP" ]; then
        sed -i "s|^description=.*|description=Disable thermal for mtk D8050/8020! Should work on other MTK devices • Tempspoof Status: Enabled!✅|" "$MODULE_PROP"
    else
        echo "Error: module.prop not found!" >&2
    fi
fi

# ================================
#      Reboot Reminder
# ================================
sleep 1
echo ""
echo "Please reboot your device!."
sleep 1