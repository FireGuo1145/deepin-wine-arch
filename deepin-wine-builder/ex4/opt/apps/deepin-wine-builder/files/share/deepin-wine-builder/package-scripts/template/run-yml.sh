#!/bin/bash

#   Copyright (C) 2016 Deepin, Inc.
#
#   Author:     Li LongYu <lilongyu@linuxdeepin.com>
#               Peng Hao <penghao@linuxdeepin.com>

export DEB_PACKAGE_NAME="@deb_package_name@"

ARCHIVE_FILE_DIR="/opt/apps/$DEB_PACKAGE_NAME/files"

export WINEPREDLL="$ARCHIVE_FILE_DIR/dlls"

if [ -z "$DISABLE_ATTACH_FILE_DIALOG" ];then
    export ATTACH_FILE_DIALOG=1
fi

if [[ -f "$ARCHIVE_FILE_DIR/installer.yml" ]]; then
    deepin-wine-bottles run "$ARCHIVE_FILE_DIR/installer.yml" "$@"
fi
