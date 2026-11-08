#!/bin/bash

#   Copyright (C) 2025 Deepin, Inc.
#

DEB_PACKAGE_NAME="@deb_package_name@"
BOTTLENAME="@public_bottle_name@"
APP_NAME="@app_name_zh_cn@"
WINEPREFIX="$HOME/.deepinwine/$BOTTLENAME"
TOOLS_DIR="/opt/deepinwine/tools"
APP_TYPE="deb"

is_banner_running()
{
    # 获取所有deepin-wine-banner进程的PID
    pids=$(pgrep -f 'deepin-wine-banner')

    # 如果没有找到进程，直接退出
    if [ -z "$pids" ]; then
        echo "未找到 deepin-wine-banner 进程"
        return 1
    fi

    # 标志变量，用于记录是否找到符合条件的进程
    found=0

    # 遍历每个PID并检查环境变量
    for pid in $pids; do
        # 读取环境变量并替换null为换行
        env_vars=$(tr '\0' '\n' < "/proc/$pid/environ")

        # 检查WINE_WMCLASS和DEB_PACKAGE_NAME的值
        wine_wmclass=$(echo "$env_vars" | grep -E '^WINE_WMCLASS=' | cut -d= -f2-)
        deb_package=$(echo "$env_vars" | grep -E '^DEB_PACKAGE_NAME=' | cut -d= -f2-)

        # 判断是否符合条件
        if [ "$wine_wmclass" = "$DEB_PACKAGE_NAME" ] && [ "$deb_package" = "$DEB_PACKAGE_NAME" ]; then
            found=1
            break  # 找到后提前退出循环
        fi
    done

    # 根据结果输出并返回退出码
    if [ $found -eq 1 ]; then
        echo "存在带有 WINE_WMCLASS 和 DEB_PACKAGE_NAME 为 $DEB_PACKAGE_NAME 的进程"
        return 0
    else
        echo "未找到符合条件的进程"
        return 2
    fi
}

# 通过进程ID获取wine路径
get_wine_by_pid()
{
    wine_path=$(cat /proc/$1/maps | grep -E "\/wine$|\/wine64$|\/wine |\/wine64 " | head -1 | awk '{print $6}')
    if [ -z "$wine_path" ];then
        cat /proc/$1/cmdline| xargs -0 -L1 -I{} echo {} | grep -E "\/wine$|\/wine64$|\/wine |\/wine64 " | head -1
    else
        echo $wine_path
    fi
}

# 判断是否为wine进程
is_wine_process()
{
    wine_module=$(get_wine_by_pid $1)
    if [ -z "$wine_module" ];then
        wine_module=$(cat /proc/$1/maps | grep -E "\/wineserver$" | head -1)
    fi
    echo $wine_module
}

# 通过进程ID获取wine前缀路径
get_prefix_by_pid()
{
    WINE_PREFIX=$(xargs -0 printf '%s\n' < /proc/$1/environ | grep WINEPREFIX)
    WINE_PREFIX=${WINE_PREFIX##*=}
    if [ -z "$WINE_PREFIX" ] && [ -n "$(is_wine_process $1)" ]; then
        #不指定容器的情况用默认容器目录
        WINE_PREFIX="$HOME/.wine"
    fi
    if [ -n "$WINE_PREFIX" ];then
        WINE_PREFIX=$(realpath $WINE_PREFIX)
        echo $WINE_PREFIX
    fi
}

get_bottle_path_by_process_id()
{
    PID_LIST="$1"
    PREFIX_LIST=""

    for pid_var in $PID_LIST ; do
        WINE_PREFIX=$(get_prefix_by_pid $pid_var)
        #去掉重复项
        for bottle_path in $(echo -e $PREFIX_LIST) ; do
            if [[ $bottle_path == "$WINE_PREFIX" ]]; then
                WINE_PREFIX=""
            fi
        done
        if [ -d "$WINE_PREFIX" ]; then
            PREFIX_LIST+="\n$WINE_PREFIX"
        fi
    done
    echo -e $PREFIX_LIST
}

get_tray_window()
{
    $TOOLS_DIR/get_tray_window | awk -F: '{print $2}'
}

get_stacking_window()
{
    xprop -root _NET_CLIENT_LIST_STACKING | awk -F# '{print $2}' | sed -e 's/, / /g'
}

get_window_pid()
{
    for winid in $(echo "$1" | sed -e 's/ /\n/g') ;
    do
        xprop -id $winid _NET_WM_PID | awk -F= '{print $2}'
    done
}

get_window_bottle()
{
    PID_LIST=$(get_window_pid "$1")
    get_bottle_path_by_process_id "$PID_LIST"
}

get_active_bottles()
{
    TRAYWINDOWS=$(get_tray_window)
    STACKINGWINDOWS=$(get_stacking_window)
    PID_LIST="$TRAYWINDOWS $STACKINGWINDOWS"
    get_window_bottle "$PID_LIST"
}

exit_code=-1
if [ -f "$TOOLS_DIR/deepin-wine-uninstall" ]; then
    if is_banner_running ;then
        echo "$APP_NAME 正在运行，请先关闭！"
        "$TOOLS_DIR/deepin-wine-uninstall" running "$APP_NAME" "$DEB_PACKAGE_NAME.$APP_TYPE" 2>&1
        exit_code=$?
    else
        ACTIVEBOTTLES=$(get_active_bottles)

        if [[ "$ACTIVEBOTTLES" != *"$WINEPREFIX"* ]]; then
            "$TOOLS_DIR/deepin-wine-uninstall" uninstall "$APP_NAME" "$DEB_PACKAGE_NAME.$APP_TYPE" 2>&1
            exit_code=$?
        else
            echo "$APP_NAME 正在运行，请先关闭！"
            "$TOOLS_DIR/deepin-wine-uninstall" running "$APP_NAME" "$DEB_PACKAGE_NAME.$APP_TYPE" 2>&1
            exit_code=$?
        fi
    fi
fi

case $exit_code in
    0)
        # 用户不勾选删除应用设置和个人数据并确认卸载返回0
        echo "用户确认卸载"
        ;;
    102)
        # 用户勾选删除应用设置和个人数据并确认卸载返回102
        # 执行预卸载脚本
        if [ -f "/opt/apps/${DEB_PACKAGE_NAME}/files/pre_uninstall.sh" ]; then
            echo "正在执行预卸载脚本..."
            "/opt/apps/${DEB_PACKAGE_NAME}/files/pre_uninstall.sh" "$exit_code"
        fi

        if [ -d "$WINEPREFIX" ];then
            "$TOOLS_DIR/kill.sh" "$WINEPREFIX"
            rm -rf "$WINEPREFIX"
            echo "卸载完成"
        fi
        exit_code=0
        ;;
    101)
        # 用户取消卸载返回101，包含用户点击右上角X按钮和取消按钮两种情况
        echo "用户取消卸载"
        ;;
    103)
        # 卸载程序已经运行返回103
        echo "deepin-wine-uninstall 已经运行"
        ;;
    *)
        echo "卸载过程发生错误"
        ;;
esac

exit $exit_code

