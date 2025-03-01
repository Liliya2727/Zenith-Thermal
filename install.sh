#!/bin/sh
# Magisk Module Configuration
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

MODPATH=${MODPATH:-/data/adb/modules_update/ZenithThermal}
tempspoofs="/sys/class/power_supply/battery/temperature"
# System Files to Replace (Will be disabled)
REPLACE="
/system/etc/init/init.thermald.rc
/system/vendor/etc/.tp/thermal.conf
/system/vendor/etc/.tp/thermal.off.conf
/system/vendor/etc/.tp/.thermal_policy_08
/system/vendor/etc/.tp/.ht120.mtc
/system/vendor/etc/init/android.hardware.thermal@2.0-service.mtk.rc
/system/vendor/etc/init/init.thermal_core.rc
"

# ================================
#        Installation Start
# ================================
sleep 1
ui_print " "
ui_print "━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "     ZenithThermal     "
ui_print "━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "- Version  : v1.6 "
ui_print "- Author   : @Zexshia"
ui_print "- Release  : 02/03/2025"
sleep 1
ui_print "- Device   : $(getprop ro.product.board)"
sleep 1
ui_print "- Installing Zenith..."
sleep 1

# Extract Required Files
ui_print "- Extracting module files..."
unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'post-fs-data.sh' -d "$MODPATH" >&2
# Check if the binary exists before extracting
sleep 3
# Ensure necessary directories exist
mkdir -p "$MODPATH/system/bin"
unzip -o "$ZIPFILE" 'Zenith' -d "$MODPATH/system/bin" >&2
if [ -f "$tempspoofs" ]; then
    ui_print "- TempSpoof is Supported! installing TempSpoof"
    sleep 1
    unzip -o "$ZIPFILE" 'action.sh' -d "$MODPATH" >&2
else
    ui_print "- TempSpoof is not Supported! Skip files!"
    touch "$MODPATH/TempUnSupport"
fi

# ================================
#     Disable Thermal Services
# ================================
ui_print "- Disabling thermal services..."

# Disable thermal-related configurations by replacing them with empty files
find /system/vendor/ -name "*thermal*" -type f -print0 | while IFS= read -r -d '' thermalsvc; do
    if [[ "$thermalsvc" == *.conf ]]; then
        dest="$MODPATH${thermalsvc#/system}"
        mkdir -p "$(dirname "$dest")"
        touch "$dest"
    fi
done >/dev/null 2>&1

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

for file in /system/vendor/etc/.tp/thermal.conf \
           /system/vendor/etc/.tp/thermal.off.conf \
           /system/vendor/etc/.tp/.thermal_policy_08 \
           /system/vendor/etc/.tp/.ht120.mtc; do
      if [ -f "$file" ]; then
        dest="$MODPATH${file#/system}"
        mkdir -p "$(dirname "$dest")"
        touch "$dest"
      fi
done

# ================================
#         Set Permissions
# ================================
ui_print "- Setting file permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/system/etc" 0 0 0755 0644
set_perm_recursive "$MODPATH/system/vendor" 0 0 0755 0644

# ================================
#         Installation Done
# ================================
sleep 1
ui_print "- ZenithThermal Installed!     "
sleep 1