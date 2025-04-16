#!/bin/bash

Root="${0%/*}"
Task="$Root/task"
Temp="$Root/temp"
Core="$Root/bin/bash"
Note="$Root/module.prop"
Time="$Root/config/计划任务.prop"
Black="$Root/config/黑名单.prop"
White="$Root/config/白名单.prop"

# 函数：信息格式化到日志文件
# 参数：
#   $1: 日志信息
#   $2: 清空文件(可选)
info() {
    local news="${1:-"Hello World!"}"
    local mode="${2:-0}"

    if [ "$mode" -eq 1 ]; then
        : >"$Temp/log"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') $news" >>"$Temp/log"
}

# 函数：初始化程序的临时目录
# 返回值：
#   0: 成功执行
#   1: 文件被删
init() {
    if [[ ! -d "$Task" ]]; then
        mkdir -p "$Task"
        chmod 755 "$Task"
    fi

    if [[ ! -d "$Temp" ]]; then
        mkdir -p "$Temp"
        chmod 755 "$Temp"
    fi

    echo 0 >"$Temp/dir"
    echo 0 >"$Temp/file"

    : >"$Temp/lock"
    : >"$Temp/log"
    : >"$Temp/omit"
    : >"$Task/root"

    chmod 644 "$Task/root"
    find "$Temp" -type f -exec chmod 644 {} \;

    # 检查配置文件是否存在
    if [[ -f "$Note.bak" && -f "$Time" && -f "$Black" && -f "$White" ]]; then
        cp -f "$Note.bak" "$Note"
        info "[信息] 程序已初始化完成！"
        return 0
    else
        info "[错误] 程序已初始化失败！"
        info "[警告] 模块配置文件缺失！"
        return 1
    fi
}

# 函数：更新模块描述信息文件
# 参数：
#   $1: 目录计数
#   $2: 文件计数
note() {
    local dir="$1"
    local file="$2"
    local note

    if [[ "$KSU" || "$APATCH" ]]; then
        note="🗑️ 本次运行已清除:\\\\n📃 $file 个黑名单文件\\\\n🗂️ $dir 个黑名单目录"
    else
        note="🗑️ 本次运行已清除: 📃 $file 个黑名单文件 | 🗂️ $dir 个黑名单目录"
    fi

    sed -i "/^description=/c description=$note" "$Note"
}

# 函数：结束定时任务所有进程
# 返回值：
#   0: 成功结束
#   1: 没有进程
kill() {
    local task=0
    local data

    while data=$(pgrep -f "$Task") && [[ -n "$data" ]]; do
        info "[信息] 定时任务正在结束..."

        for meta in $data; do
            info "[进程] $meta"
        done

        pkill -f "$Task"
        ((task++))

        sleep 1
    done

    if [ "$task" -gt 0 ]; then
        info "[信息] 定时任务已经结束。"
        return 0
    else
        return 1
    fi
}

# 函数：设置定时任务并且启动
# 返回值：
#   0: 成功运行
#   1: 运行失败
task() {
    local task
    local time
    local data

    # KernelSU
    if [[ "$KSU" ]]; then
        task="/data/adb/ksu/bin/busybox crond"

    # APatch
    elif [[ "$APATCH" ]]; then
        task="/data/adb/ap/bin/busybox crond"

    # Magisk
    else
        task="/data/adb/magisk/busybox crond"
    fi

    time=$(grep -vE '^$|#' "$Time" | head -n 1 | tr -d '\r\n')
    printf "%s %s %s %s\n" "$time" "$Core" "$Root/main.sh" "lock main" >"$Task/root"
    $task -c "$Task"

    sleep 1

    data=$(pgrep -f "$Task")

    if [[ -n "$data" ]]; then
        data=$(echo "$data" | head -n 1)

        info "[信息] 定时任务成功运行！"
        info "[进程] $data"
        info "[定时] $time"

        return 0
    else
        info "[错误] 定时任务运行失败！"
        return 1
    fi
}

# 函数：读取文件内容到数组内
# 参数：
#   $1: 文件路径
#   $2: 数组名称
read_file() {
    local file="$1"
    local -n list="$2"

    while IFS= read -r line; do
        line=$(echo "$line" | xargs)

        if [[ -n "$line" && "${line:0:1}" != "#" ]]; then
            list+=("$line")
        fi
    done <"$file"
}

# 函数：通配符匹配文件和目录
# 参数：
#   $1: 原始数据
# 返回值：匹配的文件或目录路径
make_list() {
    local data="$1"
    local form=()

    for line in $data; do
        if [[ -e "$line" ]]; then
            line="${line%/}"
            form+=("$line")
        fi
    done

    if [ "${#form[@]}" -gt 0 ]; then
        printf "%s\n" "${form[@]}"
    fi
}

# 函数：判断路径是否存在冲突
# 参数：
#   $1: 路径条目
#   $2: 路径条目
# 返回值：
#   0: 存在冲突
this_data() {
    local data="$1"
    local meta="$2"

    [[ -d "$data" && "${data: -1}" != "/" ]] && data="$data/"
    [[ -d "$meta" && "${meta: -1}" != "/" ]] && meta="$meta/"

    # 检查路径开头是否匹配
    [[ "$meta" == "$data"* ]] || [[ "$data" == "$meta"* ]]
}

# 函数：执行遍历名单删除操作
main() {
    # 声明黑名单和白名单数组
    local -a black_list
    local -a white_list
    local -a match_black
    local -a match_white

    # 读取黑名单和白名单文件
    read_file "$Black" black_list
    read_file "$White" white_list

    # 匹配黑名单和白名单条目
    mapfile -t match_black < <(for data in "${black_list[@]}"; do make_list "$data"; done)
    mapfile -t match_white < <(for data in "${white_list[@]}"; do make_list "$data"; done)

    # 读取计数器
    local dir
    local file
    local omit="$Temp/omit"
    file=$(<"$Temp/file")
    dir=$(<"$Temp/dir")

    local black

    # 遍历黑名单
    for black in "${match_black[@]}"; do
        # 跳过不存在的条目
        if [[ ! -e "$black" ]]; then
            # info "[忽略] 目标不存在: $black"
            continue
        fi

        local skip=0
        local white

        # 遍历白名单
        for white in "${match_white[@]}"; do
            local mark=0

            # 检查是否已打印过
            if grep -q "^$white$" "$omit"; then
                mark=1
            fi

            # 跳过全匹配的条目
            if [[ "$black" == "$white" ]]; then
                if [ "$mark" -eq 0 ]; then
                    info "[跳过] 白名单条目: $white"
                    echo "$white" >>"$omit"
                fi

                skip=1
                break

            # 跳过父子关系条目
            elif this_data "$black" "$white"; then
                if [ "$mark" -eq 0 ]; then
                    info "----------------"
                    info "[跳过] 黑名单条目: $black"
                    info "[关联] 白名单条目: $white"
                    info "----------------"
                    echo "$white" >>"$omit"
                fi

                skip=1
                break
            fi
        done

        if [ "$skip" -eq 1 ]; then
            continue
        fi

        # 如果是目录
        if [[ -d "$black" ]]; then
            rm -rf "$black" && {
                info "[删除] 黑名单目录: $black/"
                ((dir++))
            }

        # 如果是文件
        elif [[ -f "$black" ]]; then
            rm -rf "$black" && {
                info "[删除] 黑名单文件: $black"
                ((file++))
            }
        fi
    done

    # 写入计数器
    echo "$dir" >"$Temp/dir"
    echo "$file" >"$Temp/file"

    # 更新模块描述信息
    note "$dir" "$file"
}

# 函数：检测设备实时锁屏状态
# 参数：
#   $1: 函数名称(可选)
# 返回值：锁屏状态
lock() {
    local lock
    local file="$Temp/lock"
    local node="${1:-default}"

    lock=$(dumpsys window policy | grep 'mInputRestricted' | cut -d= -f2)

    if [[ -z "$lock" ]]; then
        info "[错误] 获取锁屏状态失败！"
        return 1
    fi

    if [[ "$lock" == "true" ]]; then
        lock="锁屏"

        # 检查是否已打印过
        if ! grep -q "locked" "$file"; then
            echo "locked" >"$file"
            info "[信息] $lock"
        fi

        # 检查是否传入函数
        if [[ "$node" != "default" ]]; then
            return 0
        fi

        echo "$lock"
    else
        lock="解锁"

        if ! grep -q "unlock" "$file"; then
            echo "unlock" >"$file"
            info "[信息] $lock"
        fi

        if [[ "$node" != "default" ]]; then
            if [[ "$node" == "lock" ]]; then
                info "[错误] 不能运行'$node'本身！"
                return 1
            fi

            if ! grep -q "$node" "$file"; then
                echo "$node" >>"$file"
                info "[信息] 正在执行'$node'函数..."
            fi

            code_work "$node"
            return 0
        fi

        echo "$lock"
    fi
}

# 函数：未指定函数时显示说明
help() {
    echo ""
    echo "# 用法: bash main.sh function args"
    echo "#"
    echo "# 说明:"
    echo "# - bash: 指定解释器的路径"
    echo "# - main.sh: 当前脚本的文件名"
    echo "# - function: 需要调用的函数名"
    echo "# - args: 传递给函数的参数(可选)"
    echo "#"
    echo "# 示例:"
    echo "# /path/to/bash main.sh info hello"
    echo "#"
    echo "# 可用的函数:"
    echo "# - init: 初始化"
    echo "# - info: 打印消息"
    echo "# - task: 运行定时"
    echo "# - kill: 结束定时"
    echo "# - lock: 检测锁屏"
    echo "# - main: 运行清理"
}

# 函数：执行脚本里的其它函数
# 参数：
#   $1: 函数名称
code_work() {
    local node="$1"

    # 检查是否传入函数
    if [[ "$#" -eq 0 || -z "$1" ]]; then
        help
        exit 1
    fi

    # 检查脚本运行环境
    if [[ ! "$ASH_STANDALONE" ]]; then
        echo "[错误] 请在独立模式运行！"
        exit 1
    fi

    # 检查是否传入本体
    if [[ "$node" == "code_work" ]]; then
        echo "[错误] 不能自己运行自己！"
        exit 1
    fi

    # 检查函数名并执行
    if declare -f "$node" >/dev/null; then
        "$node" "${@:2}"
    else
        echo "[错误] 函数'$node'不存在！"
        exit 1
    fi
}

code_work "$@"
