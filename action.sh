#!/system/bin/sh

# 检查脚本运行环境
if [ ! "$ASH_STANDALONE" ]; then
    echo "[错误] 请在独立模式运行！"
    exit 1
fi

Root="${0%/*}"
Core="$Root/bin/bash"

$Core $Root/main.sh kill

if [ $? -eq 0 ]; then
    echo "[信息] 定时任务已经结束。"
else
    $Core $Root/main.sh init

    if [ $? -ne 0 ]; then
        echo "[错误] 程序已初始化失败！"
        echo "[警告] 模块配置文件缺失！"
    else
        $Core $Root/main.sh task

        if [ $? -ne 0 ]; then
            echo "[警告] 定时任务运行失败！"
        else
            echo "[信息] 定时任务成功运行！"
            $Core $Root/main.sh lock main
        fi
    fi
fi

# 操作页面退出等待
sleep 2
