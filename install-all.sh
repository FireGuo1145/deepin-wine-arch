#!/bin/bash
# 按依赖顺序构建并安装本仓库的包。
# 注意：makepkg 不能以 root 运行，所以这里用普通用户构建、sudo 只用于 pacman -U。
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "请不要用 root 运行本脚本（makepkg 会拒绝执行）。" >&2
    exit 1
fi

PKGS=(deepin-wine10-stable deepin-wine-extras deepin-wine-builder)
if [[ ${1:-} == "--all" ]]; then
    PKGS+=(deepin-wine11-stable deepin-wine-staging deepin-wine-logtool)
fi

for p in "${PKGS[@]}"; do
    printf '\n==> %s\n' "$p"
    ( cd "$p" && makepkg -f --nocheck )
done

echo
echo "==> 安装（需要 sudo）"
for p in "${PKGS[@]}"; do
    mapfile -t files < <(find "$p" -maxdepth 1 -name '*.pkg.tar.zst' ! -name '*-debug-*' | sort)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "  $p: 没找到构建产物，跳过" >&2
        continue
    fi
    sudo pacman -U --needed --noconfirm "${files[@]}"
done

cat <<'EOF'

==> 完成。桌面环境里应能看到「统信Windows应用兼容引擎」。
    想让 .exe 双击就用它打开，按需执行：
      xdg-mime default deepin-wine-builder.desktop application/x-ms-dos-executable
      xdg-mime default deepin-wine-builder.desktop application/x-msi
EOF
