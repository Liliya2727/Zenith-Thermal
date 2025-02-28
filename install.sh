#!/bin/sh

SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true
REPLACE="

"

sleep 2
ui_print
ui_print
ui_print "      ZenithThermal!      "
ui_print 
ui_print
ui_print "- Releases : 27/02/2025"
ui_print "- Author : @Zexshia"
ui_print "- Version : 1.3 Stable"
sleep 1
ui_print "- Device : $(getprop ro.product.board) "
sleep 2
ui_print "- Installing Zenith!"
sleep 1
ui_print "- Extracting module files.."
sleep 1
unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'action.sh' -d "$MODPATH" >&2
mkdir -p $MODPATH/system/bin
unzip -o "$ZIPFILE" 'Zenith' -d $MODPATH/system/bin >&2

find /system/vendor/ -name "*thermal*" -type f -print0 | while IFS= read -r -d '' nama; do
   if [[ "$thermalsvc" == *.conf ]]; then
     mkdir -p "$MODPATH/$thermalsvc"
     rmdir "$MODPATH/$thermalsvc"
     touch "$MODPATH/$thermalsvc"
   fi
done >/dev/null 2>&1
sleep 1
if [ -f /system/bin/thermald ]; then
    mkdir -p $MODPATH/system/bin/thermald
    rmdir $MODPATH/system/bin/thermald
    touch $MODPATH/system/bin/thermald
fi
if [ -f /system/vendor/bin/thermal_core ]; then
    mkdir -p $MODPATH/system/vendor/bin/thermal_core
    rmdir $MODPATH/system/vendor/bin/thermal_core
    touch $MODPATH/system/vendor/bin/thermal_core
fi
if [ -f /system/vendor/bin/thermal_intf ]; then
    mkdir -p $MODPATH/system/vendor/bin/thermal_intf
    rmdir $MODPATH/system/vendor/bin/thermal_intf
    touch $MODPATH/system/vendor/bin/thermal_intf
fi
if [ -f /system/lib64/libthermalservice.so ]; then
    mkdir -p $MODPATH/system/lib64/libthermalservice.so
    rmdir $MODPATH/system/lib64/libthermalservice.so
    touch $MODPATH/system/lib64/libthermalservice.so
fi
if [ -f /system/etc/init/init.thermald.rc ]; then
    mkdir -p $MODPATH/system/etc/init/init.thermald.rc
    rmdir $MODPATH/system/etc/init/init.thermald.rc
    touch $MODPATH/system/etc/init/init.thermald.rc
fi
if [ -f /system/vendor/etc/init/android.hardware.thermal@2.0-service.mtk.rc ]; then
   mkdir -p $MODPATH/system/vendor/etc/init/android.hardware.thermal@2.0-service.mtk.rc
   rmdir $MODPATH/system/vendor/etc/init/android.hardware.thermal@2.0-service.mtk.rc
   touch $MODPATH/system/vendor/etc/init/android.hardware.thermal@2.0-service.mtk.rc
fi
if [ -f /system/vendor/etc/init/init.thermal_core.rc ]; then
    mkdir -p $MODPATH/system/vendor/etc/init/init.thermal_core.rc
    rmdir $MODPATH/system/vendor/etc/init/init.thermal_core.rc
    touch $MODPATH/system/vendor/etc/init/init.thermal_core.rc
fi

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/vendor 0 0 0755 0755
set_perm_recursive $MODPATH/system 0 0 0755 0755
  
