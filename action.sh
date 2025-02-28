#!/system/bin/sh
MODDIR="$(dirname "$0")"
batteryspoof="$MODDIR/spooftemp"

if [ -f "$batteryspoof" ]; then
    echo ""
    echo "ZENITH THERMAL!"
    echo ""
    sleep 3
    echo ""
    echo "Disabling Temp Spoof.."
    sleep 3
    echo ""
    echo "Temp Spoof is Disabled!"
    echo "done"
    sleep 1
    echo "Please reboot the devices!"
    
    rm -f "$batteryspoof" 
else
    echo ""
    echo "ZENITH THERMAL!"
    echo ""
    sleep 3
    echo ""
    echo "Enabling Temp Spoof.."
    sleep 3
    echo ""
    echo "Temp Spoof is Enabled!"
    echo "done"
    sleep 1
    echo "Please reboot the devices!"
    touch "$batteryspoof" 
fi