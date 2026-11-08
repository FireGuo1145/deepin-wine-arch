#!/usr/bin/env bash

here="$( cd "$(dirname "$0")" || exit ; pwd)"

# wine install dir
dir=/opt/deepin-wine-staging/lib/wine/x86_64-windows/
out="$here/wine_builtin_dlls.txt"

# 用来生成 wine 自带的 dll 列表
find "$dir" -name '*.dll' -type f -exec basename {} \; | sed 's/\.dll$//' | sort | uniq >> "$out"
