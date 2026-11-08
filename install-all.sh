#!/bin/bash
# 按依赖顺序构建并安装本仓库的包。
#
# makepkg 不能以 root 运行，所以：普通用户构建，sudo 只用于 pacman。
# 每个包「先装好再装下一个」，这样 deepin-wine-builder 对 deepin-wine10-stable
# 的依赖可以由本地构建的包满足（不会去仓库里找）。
#
# 用法：
#   ./install-all.sh            装 wine10 + extras + builder
#   ./install-all.sh --all      连 wine11 / staging / logtool 一起装
#   ./install-all.sh --build-only   只构建，不安装
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "请不要用 root 运行本脚本（makepkg 会拒绝执行）。" >&2
    exit 1
fi

BUILD_ONLY=0
ALL=0
for a in "$@"; do
    case $a in
        --all) ALL=1 ;;
        --build-only) BUILD_ONLY=1 ;;
        *) echo "未知参数: $a" >&2; exit 1 ;;
    esac
done

PKGS=(deepin-wine10-stable deepin-wine-extras deepin-wine-builder)
[[ $ALL -eq 1 ]] && PKGS+=(deepin-wine11-stable deepin-wine-staging deepin-wine-logtool)

install_pkgs=()
for p in "${PKGS[@]}"; do
    printf '\n==> 构建 %s\n' "$p"
    # -s: 自动补装仓库里的依赖（会调用 sudo）；--needed 避免重复装
    ( cd "$p" && makepkg -f --nocheck -s --needed )

    mapfile -t files < <(find "$p" -maxdepth 1 -name '*.pkg.tar.zst' ! -name '*-debug-*' | sort)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "$p: 没找到构建产物" >&2
        exit 1
    fi
    install_pkgs+=("${files[@]}")

    if [[ $BUILD_ONLY -eq 0 ]]; then
        printf '==> 安装 %s\n' "$p"
        sudo pacman -U --needed --noconfirm "${files[@]}"
    fi
done

if [[ $BUILD_ONLY -eq 1 ]]; then
    echo
    echo "只构建模式，产物："
    printf '  %s\n' "${install_pkgs[@]}"
    exit 0
fi

cat <<'EOF'

==> 完成。应用菜单里应出现「统信Windows应用兼容引擎」，或直接运行：
      deepin-wine-builder
    让 .exe 双击就用它打开（可选）：
      xdg-mime default deepin-wine-builder.desktop application/x-ms-dos-executable
      xdg-mime default deepin-wine-builder.desktop application/x-msi
EOF
