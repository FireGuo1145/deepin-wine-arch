#!/bin/bash

# 参数1传入要对比的容器目录

SHELL_DIR=$(realpath "$0" | xargs -i dirname {})
DEF_BOTTLE_PATH="$HOME/.deepinwine/default"
TARGET_BOTTLE_PATH="$HOME/.deepinwine/target"
BOTTLE_ARCH="win64"
if [ -z "$RUN_CMD" ];then
    RUN_CMD="deepin-wine10-stable"
fi

clean_bottle()
{
    "${SHELL_DIR}/cleanbottle.sh" "$1" $RUN_CMD &> /dev/null
}

make_default_bottle()
{
    if [ -d "$DEF_BOTTLE_PATH" ];then
        rm -rf "$DEF_BOTTLE_PATH"
    fi

    WINESERVICESNODELAY=upstream WINEARCH="$BOTTLE_ARCH" WINEPREFIX="$DEF_BOTTLE_PATH" $RUN_CMD uninstaller --list
    clean_bottle "$DEF_BOTTLE_PATH"
}

print_reg_diff()
{
    echo ""
    echo "diff of user.reg"
    diff "$1/user.reg" "$2/user.reg" | grep -v -E "\[.*\] |#time=" | grep -E "^< \"|^> \""
    echo ""
    echo "diff of system.reg"
    diff "$1/system.reg" "$2/system.reg" | grep -v -E "\[.*\] |#time=" | grep -E "^< \"|^> \""
    echo ""
    echo "diff of userdef.reg"
    diff "$1/userdef.reg" "$2/userdef.reg" | grep -v -E "\[.*\] |#time=" | grep -E "^< \"|^> \""
}

make_diff_list()
{
    if [ ! -f "$1/user.reg" ];then
        echo "未找到$1/user.reg文件，$1不是一个有效的容器目录"
        exit
    fi

    if [ ! -f "$2/user.reg" ];then
        echo "未找到$2/user.reg文件，$2不是一个有效的容器目录"
        exit
    fi

    BOTTLE_NAME=$(basename "$1")
    DIFF_LIST="/tmp/${BOTTLE_NAME}.diff"

    LANG=Utf8 diff -qr --exclude "dosdevices" "$1" "$2" > "$DIFF_LIST"

    filter_diff_list

    print_reg_diff "$@" >> "$DIFF_LIST"

    cat "$DIFF_LIST"

    if [ -f "$review_log" ]; then
        echo "容器修改内容如下:" >> "$review_log"
        cat "$DIFF_LIST" >> "$review_log"
    fi
}

filter_diff_list()
{
    if [ -f "$DIFF_LIST" ];then
        cat "$DIFF_LIST" | grep -E "Files.*and.*differ" | while read diff_line;do
            def_file=$(echo $diff_line | awk -F " and " '{print $1}' | awk -F "Files " '{print $NF}')
            bottle_file=$(echo $diff_line | awk -F " and " '{print $NF}'| awk -F " differ" '{print $1}')

            is_fake_dll_def=$(/opt/$RUN_CMD/bin/winedump "$def_file" | grep "This is a Wine fake DLL")
            is_fake_dll_bottle=$(/opt/$RUN_CMD/bin/winedump "$bottle_file" | grep "This is a Wine fake DLL")
            if [[ -n "$is_fake_dll_def" ]] && [[ -n "$is_fake_dll_bottle" ]];then
                sed -i "s#$diff_line##" "$DIFF_LIST"
            fi
        done
    fi
    sort -u "$DIFF_LIST" > /tmp/t.diff
    mv "/tmp/t.diff" "$DIFF_LIST"
}

print_helper()
{
    echo "-bottle diff form default bottle"
    echo "-deb diff form default bottle"
    echo "-setup diff form default bottle"
}

make_setup_target_bottle()
{
    if [ -d "$TARGET_BOTTLE_PATH" ];then
        rm -rf "$TARGET_BOTTLE_PATH"
    fi

    WINESERVICESNODELAY=upstream WINEARCH="$BOTTLE_ARCH" WINEPREFIX="$TARGET_BOTTLE_PATH" $RUN_CMD "$1" &> /dev/null
    clean_bottle "$TARGET_BOTTLE_PATH"
}

make_deb_target_bottle()
{
    if [ -d "$TARGET_BOTTLE_PATH" ];then
        rm -rf "$TARGET_BOTTLE_PATH"
    fi

    deb_package_name=$(dpkg -I "$1" | grep "Package:" | awk '{print $NF}')
    if [ -z "$deb_package_name" ];then
        echo "$1 package name not found"
        exit
    fi

    dpkg -x "$1" deb
    7z x "deb/opt/apps/$deb_package_name/files/files.7z" -o"$TARGET_BOTTLE_PATH"
    mv "$TARGET_BOTTLE_PATH/drive_c/users/@current_user@" "$TARGET_BOTTLE_PATH/drive_c/users/$USER"
    sed -i "s#@current_user@#$USER#" "$TARGET_BOTTLE_PATH"/*.reg
    BOTTLE_ARCH=$(cat "$TARGET_BOTTLE_PATH/user.reg" | grep arch= | awk -F = '{print $NF}')
    clean_bottle "$TARGET_BOTTLE_PATH"
}

make_target_bottle()
{
    if [ ! -f "$1/user.reg" ];then
        echo "$1/user.reg not found"
        exit
    fi
    BOTTLE_ARCH=$(cat "$1/user.reg" | grep arch= | awk -F = '{print $NF}')
    TARGET_BOTTLE_PATH="$1"

    if [ -n "$2" ];then
        if [ "$2" != "$BOTTLE_ARCH" ];then
            echo "两个容器架构不一致"
        fi
    fi
}

make_source_bottle()
{
    if [ ! -f "$1/user.reg" ];then
        echo "$1/user.reg not found"
        exit
    fi
    BOTTLE_ARCH=$(cat "$1/user.reg" | grep arch= | awk -F = '{print $NF}')
    DEF_BOTTLE_PATH="$1"
}

# 如果指定了对比容器，先通过对比的源容器初始化WINEARCH
if [ -n "$3" ];then
    make_source_bottle "$3"
fi
if [ "$1" = "-bottle" ];then
    if [ -n "$3" ];then
        make_target_bottle "$2" "$BOTTLE_ARCH"
    else
        make_target_bottle "$2"
    fi
elif [ "$1" = "-deb" ];then
    make_deb_target_bottle "$2"
elif [ "$1" == "-setup" ];then
    make_setup_target_bottle "$2"
else
    print_helper
    exit
fi
# 如果没有指定容器用目标容器初始化的WINEARCH创建默认容器
if [ -z "$3" ];then
    make_default_bottle
fi

make_diff_list "$DEF_BOTTLE_PATH" "$TARGET_BOTTLE_PATH"
