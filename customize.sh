#!/system/bin/sh

# 跳过默认安装流程
SKIPUNZIP=1

Path="$MODPATH"
File="$ZIPFILE"
Nova="$Path/config"
Note="$Path/module.prop"

Move="/data/adb/crond_clean"

# 解压文件
unzip -o "$File" -x "config/*" -x "META-INF/*" -x "customize.sh" -d "$Path"

if [ ! -d "$Move" ]; then
    mkdir -p "$Move"
    chmod 755 "$Move"

    unzip -j "$File" "config/*" -d "$Move"
    find "$Move" -type f -exec chmod 644 {} \;
fi

ln -s "$Move" "$Nova"

# 修改描述
Author="后宫学长"
Module="定时清理"

sed -i "/^name=/c name=$Module" "$Note"
sed -i "/^author=/c author=$Author" "$Note"

find "$Path" -type d -exec chmod 755 {} \;
find "$Path" -type f -exec chmod 644 {} \;
