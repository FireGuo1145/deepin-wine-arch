#!/bin/sh
# deepin-wine-builder 启动器（Arch 打包版）
#
# 为什么需要这层包装：
#   1) 上游二进制由 UOS 的 Qt 6.8 构建，依赖 QListView::eventFilter /
#      QListView::mousePressEvent 两个已导出符号；Arch 的 Qt 6.12 把它俩
#      并进了 QAbstractItemView，不再导出。libqt68compat.so 补上同名符号并
#      转发到基类实现。
#   2) 上游二进制写死了 libyaml-cpp.so.0.7 这个 SONAME，Arch 提供的是更新的
#      版本，这里在运行期建一个指向现有实现的兼容软链。
#
# 用 ld.so --preload 而不是 LD_PRELOAD：预加载只作用于本进程，不会泄漏给
# wine / dpkg / python 等子进程。

_libdir=/usr/lib/deepin-wine-builder
_compat="${XDG_RUNTIME_DIR:-/tmp}/deepin-wine-builder-compat-${UID:-$(id -u)}"

if mkdir -p "$_compat" 2>/dev/null; then
    for _y in /usr/lib/libyaml-cpp.so.0.*; do
        [ -e "$_y" ] || continue
        case "$_y" in
            *.so.0.7) ;;                      # 已经是 0.7，直接用
            *) ln -sf "$_y" "$_compat/libyaml-cpp.so.0.7" && break ;;
        esac
    done
fi

export QT_PLUGIN_PATH="/usr/lib/qt6/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"

exec /usr/lib/ld-linux-x86-64.so.2 \
    --preload "$_libdir/libqt68compat.so" \
    --library-path "$_compat:$libdir" \
    /opt/apps/deepin-wine-builder/files/bin/deepin-wine-builder "$@"
