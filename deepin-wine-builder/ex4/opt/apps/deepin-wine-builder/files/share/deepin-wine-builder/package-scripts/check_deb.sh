#!/bin/bash

if [ ! -f "$1" ];then
    echo "请输入待检查的deb文件"
    exit
fi

TMP_DIR="/tmp/deb_check"
if [ ! -d "$TMP_DIR" ];then
    mkdir "$TMP_DIR"
fi

dpkg -x "$1" "$TMP_DIR"

if [ $? != 0 ];then
    echo "解压$1失败, 请清理磁盘空间重试"
    exit
fi

cd "$TMP_DIR"
BOTTLE_FILE=$(find . -name files.7z)
if [ ! -f "$BOTTLE_FILE" ];then
    echo "未找到容器压缩包，打包不规范"
    exit
fi

if [ -d "./bottle" ];then
    rm -rf ./bottle
fi
7z x "$BOTTLE_FILE" -o"./bottle"

if [ $? == 0 ];then
    WIN_FONTS=$(ls ./bottle/drive_c/windows/Fonts)
    if [ -n "$WIN_FONTS" ];then
        echo ""
        ls ./bottle/drive_c/windows/Fonts
        echo "容器中打包了字体，需要在pms提bug，将上面输出的字体信息备注到bug单中。开发备注打包字体的原因，以及是否会侵犯版权，必须项目组确认通过方可上架"
    else
        echo "没有打包字体，验证通过"
    fi
else
    echo ""
    echo "解压$BOTTLE失败，请清理磁盘空间重试"
fi

rm -rf "$TMP_DIR"
