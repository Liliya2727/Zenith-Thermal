#!/bin/sh

# Magisk Module Configuration
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

MODPATH=${MODPATH:-/data/adb/modules_update/ZenithThermal}

# Files to Replace in System
REPLACE="
/system/etc/init/init.thermald.rc
/system/vendor/etc/init/android.hardware.thermal@2.0-service.mtk.rc
/system/vendor/etc/init/init.thermal_core.rc
"

sleep 2

# Display Installation Information
ui_print " "
ui_print " "
ui_print "      ZenithThermal!      "
ui_print " "
ui_print " "
ui_print "- Releases : 28/02/2025"
ui_print "- Author : @Zexshia"
ui_print "- Version : 1.3 Stable"
sleep 1
ui_print "- Device : $(getprop ro.product.board) "
sleep 2
ui_print "- Installing Zenith!"
sleep 1
ui_print "- Extracting module files.."
sleep 1

# Extract Files
unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'action.sh' -d "$MODPATH" >&2
mkdir -p $MODPATH/system/bin
unzip -o "$ZIPFILE" 'Zenith' -d $MODPATH/system/bin >&2

# Replace all thermal-related config files with empty files
find /system/vendor/ -name "*thermal*" -type f -print0 | while IFS= read -r -d '' thermalsvc; do
    case "$thermalsvc" in
        *.conf)
            dest="$MODPATH${thermalsvc#/system}"
            mkdir -p "$(dirname "$dest")"
            touch "$dest"
            ;;
    esac
done >/dev/null 2>&1

sleep 1

# List of thermal-related files to disable
# Disable thermal files by replacing them with empty files
for file in /system/bin/thermald \
            /system/vendor/bin/thermal_core \
            /system/vendor/bin/thermal_intf \
            /system/lib64/libthermalservice.so \
            /system/etc/init/init.thermald.rc \
            /system/vendor/etc/init/android.hardware.thermal@2.0-service.mtk.rc \
            /system/vendor/etc/init/init.thermal_core.rc; do
    if [ -f "$file" ]; then
        dest="$MODPATH${file#/system}"
        mkdir -p "$(dirname "$dest")"
        touch "$dest"
    fi
done

# Set Permissions
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/system/bin 0 0 0755 0755
set_perm_recursive $MODPATH/system/etc 0 0 0755 0644
set_perm_recursive $MODPATH/system/vendor 0 0 0755 0644