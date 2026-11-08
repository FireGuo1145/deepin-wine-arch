#!/usr/bin/env bash

where_am_i=$(cd "$(dirname "$0")" || exit 1; pwd)

if [ "$1" = "-c" ]; then
    "${where_am_i}/check_proton.sh"
    exit $?
fi

install_script=(/opt/deepin-ge-proton*/install.py)
if [ -f "${install_script[0]}" ]; then
    "${install_script[0]}"
    exit $?
else
    echo "Proton is not installed."
    exit 1
fi