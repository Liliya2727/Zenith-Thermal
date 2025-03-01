#!/system/bin/sh
LOGFILE="/data/local/tmp/Zenith.log"
TempUnSupport="/data/adb/modules/ZenithThermal/TempUnSupport"
MODULE_PROP="/data/adb/modules/ZenithThermal/module.prop"


if [ ! -f "$TempUnSupport" ]; then
        echo "Tempspoof is Supported"
else        
        sed -i "s|^description=.*|description=Disable thermal for mtk D8050/D8020! Should work on other MTK devices • Tempspoof Unsupported!|" "$MODULE_PROP"
        
fi