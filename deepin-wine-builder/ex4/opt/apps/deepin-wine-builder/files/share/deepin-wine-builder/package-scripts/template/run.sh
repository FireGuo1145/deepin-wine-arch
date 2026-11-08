#!/bin/bash

#   Copyright (C) 2016 Deepin, Inc.
#
#   Author:     Li LongYu <lilongyu@linuxdeepin.com>
#               Peng Hao <penghao@linuxdeepin.com>

version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

ACTIVEX_NAME="@activex_name@"
BOTTLENAME="@public_bottle_name@"
APPVER="@deb_version_string@"
EXEC_PATH="@exec_path@"
export EXEC_WORKDIR="@exec_workdir@"
START_SHELL_PATH="@start_shell_path@"
export MIME_TYPE="@mime_type@"
export MIME_EXEC="@mime_exec@"
export DEB_PACKAGE_NAME="@deb_package_name@"
export APPRUN_CMD="@apprun_cmd@"
DISABLE_ATTACH_FILE_DIALOG="@DISABLE_ATTACH_FILE_DIALOG@"
EXPORT_ENVS="@EXPORT_ENVS@"
EXEC_NAME="@desktop_file_main_exe@"
INSTALL_SETUP="@install_setup@"
export BOX86_EMU_CMD="@BOX86_CMD@"
export DEF_EMU_NAME="@def_emu_name@"
export SPECIFY_SHELL_DIR=${START_SHELL_PATH%/*}
export WINESERVICESNODELAY="@wine_services_no_delay@"
export WINESERVICESDISABLE="@wine_services_disable@"
export WINE_WMCLASS="@wm_class_name@"

ARCHIVE_FILE_DIR="/opt/apps/$DEB_PACKAGE_NAME/files"

if [ -z "$APPRUN_CMD" ];then
    export APPRUN_CMD="/opt/deepin-wine10-stable/bin/wine"
fi
if [ -f "$APPRUN_CMD" ];then
    wine_path=$(dirname $APPRUN_CMD)
    wine_path=$(realpath "$wine_path/../")
    export WINEDLLPATH=$wine_path/lib:$wine_path/lib64
else
    export WINEDLLPATH=/opt/$APPRUN_CMD/lib:/opt/$APPRUN_CMD/lib64
fi

export WINEPREDLL="$ARCHIVE_FILE_DIR/dlls"

_SetRegistryValue()
{
    env WINEPREFIX="$BOTTLEPATH" $APPRUN_CMD reg ADD "$1" /v "$2" /t "$3" /d "$4" /f
}

if [ -z "$DISABLE_ATTACH_FILE_DIALOG" ];then
    export ATTACH_FILE_DIALOG=1
fi

if [ -n "$EXPORT_ENVS" ];then
    export $EXPORT_ENVS
fi

# 打包安装程序的情况
if [[ -z "$EXEC_PATH" ]] && [[ -n "$INSTALL_SETUP" ]];then
    $START_SHELL_PATH $BOTTLENAME $APPVER "$EXEC_PATH" -c
    BOTTLEPATH="$HOME/.deepinwine/$BOTTLENAME"
    EXEC_PATH=$(find "$BOTTLEPATH" -name $EXEC_NAME | head -1)
    if [ -z "$EXEC_PATH" ];then
        _SetRegistryValue "HKCU\\Software\\Wine\\DllOverrides" winemenubuilder.exe REG_SZ
        WINEPREFIX="$BOTTLEPATH" $APPRUN_CMD "$ARCHIVE_FILE_DIR/$INSTALL_SETUP"
        EXEC_PATH=$(find "$BOTTLEPATH" -name $EXEC_NAME | head -1)

        cp "$ARCHIVE_FILE_DIR/setup.md5sum" "$BOTTLEPATH"
    fi

    if [ -z "$EXEC_PATH" ];then
        echo "安装失败退出"
        exit
    fi
fi

if [ -n "$EXEC_PATH" ];then
    if [ -z "${EXEC_PATH##*.lnk*}" ];then
        $START_SHELL_PATH $BOTTLENAME $APPVER "C:/windows/command/start.exe" "/Unix" "$EXEC_PATH" "$@"
    elif [ -z "${EXEC_PATH##*.bat}" ];then
        $START_SHELL_PATH $BOTTLENAME $APPVER "cmd" -f /c "$EXEC_PATH" "${@:2}"
    else
        $START_SHELL_PATH $BOTTLENAME $APPVER "$EXEC_PATH" "$@"
    fi
elif [ -n "$ACTIVEX_NAME" ] && [ $# -gt 1 ];then
    $START_SHELL_PATH $BOTTLENAME $APPVER "$1" -f "${@:2}"
else
    $START_SHELL_PATH $BOTTLENAME $APPVER "uninstaller.exe" "$@"
fi
