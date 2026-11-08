#!/bin/sh

# $1 修复的目录路径
# $2 包名,用来判断是否执行修复
# $3 wine名字如deepin-wine5-stable

BOTTLE_PATH="$1"
PACKAGE_NAME="$2"
userdir=$USER

fix_test()
{
    if [ "$PACKAGE_NAME" = "com.xunjiepdf.deepin" ]; then
        find "$BOTTLE_PATH/drive_c/users" -name \*.reg | xargs -i sed -i "s#$USER#@current_user@#" {}
    fi
}

echo "Fix for: $@"

fix_test
