#!/bin/sh

SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true
REPLACE="

"

sleep 2
ui_print
ui_print
ui_print "          ZenithThermal           "
ui_print 
ui_print
ui_print "- Releases : **/**/2025"
ui_print "- Author : @Zexshia"
ui_print "- Version : 1.0Test"
sleep 1
ui_print "- Device : $(getprop ro.product.board) "
sleep 2
ui_print "- Installing Zenith!"
sleep 1
ui_print "- Extracting module files.."
sleep 1
mkdir -p $MODPATH/system/bin
unzip -o "$ZIPFILE" 'Zenith' -d $MODPATH/system/bin >&2
unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2

set_perm_recursive $MODPATH 0 0 0777 0777
set_perm_recursive $MODPATH/vendor 0 0 0777 0777
set_perm_recursive $MODPATH/system 0 0 0777 0777
  
