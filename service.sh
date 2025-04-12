#!/system/bin/sh

Root="${0%/*}"
Core="$Root/bin/bash"

# 文件添加执行权限
chmod +x $Root/main.sh
chmod +x $Core

$Core $Root/main.sh init

if [ $? -ne 0 ]; then
    exit 1
fi

# 等待系统启动完成
while [[ "$(getprop sys.boot_completed)" != "1" ]]; do
    sleep 2
done

$Core $Root/main.sh info "[信息] 设备系统启动完成！"

sleep 2

$Core $Root/main.sh task

if [ $? -ne 0 ]; then
    exit 1
fi

Auld=0
Wait=60
Time=$(($(date +%s) + Wait))

# 等待用户解锁屏幕
while [ $(date +%s) -lt $Time ]; do
    Lock=$($Core $Root/main.sh lock)

    if [[ $? -eq 0 && "$Lock" == "解锁" ]]; then
        $Core $Root/main.sh lock main
        Auld=1
        break
    fi

    sleep 2
done

if [ $Auld -eq 0 ]; then
    $Core $Root/main.sh info "[信息] 超时"
    $Core $Root/main.sh info "[信息] 等待定时任务执行..."
fi
