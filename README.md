# deepin-wine-builder —— Arch Linux 打包仓库

把统信 UOS 应用商店里的 **deepin-wine-builder**（统信 Windows 应用兼容引擎，提供并替代
`deepin-wine-runner`）重新打包成 pacman 能装的形式。

- 上游来源：`https://com-store-packages.uniontech.com/appstore-V25`，suite `crimson`，component `appstore`
- 上游包：`deepin-wine-builder 4.0.2+v25-1`（amd64 deb，SHA256 见 `PKGBUILD` 里的 `_debsha256`）
- 本仓库版本：`deepin-wine-builder 4.0.2+v25-1`（x86_64）

## 构建与安装

```bash
git clone <本仓库地址> deepin-wine-builder && cd deepin-wine-builder
makepkg -si
```

`makepkg` 会在 `prepare()` 里自己去商店下载 deb（商店 CDN 有防盗链，必须带 Referer，所以
没法交给 makepkg 内置下载器）。如果你已经手工下好：

```bash
# 把 deepin-wine-builder_4.0.2+v25-1_amd64.deb 放到本目录，makepkg 会自动复用并校验 SHA256
makepkg -si
```

只构建不安装：`makepkg -s`；产物在 `deepin-wine-builder-4.0.2+v25-1-x86_64.pkg.tar.zst`。

卸载：`sudo pacman -Rns deepin-wine-builder`

## 依赖

由 pacman 自动解决（`depends`）：

| 依赖 | 用途 |
| --- | --- |
| `qt6-base` `qt6-5compat` `qt6-declarative` | 上游用 Qt 6.8 构建，需要 Core/Gui/Widgets/Network/Sql/Xml/DBus/Concurrent、Core5Compat、Qml |
| `dtk6core` `dtk6gui` `dtk6widget` `dtk6log` | Deepin Tool Kit 6（Arch 的 `deepin` 软件组里就有） |
| `libarchive` `yaml-cpp` `vulkan-icd-loader` `libx11` | 解包引擎、配置解析、Vulkan、X11 |
| `python` | 包内自带的 python 辅助脚本 |
| `hicolor-icon-theme` | 图标主题 |

可选（`optdepends`）：`unrar`、`cabextract`（解安装包）、`fakeroot`、`dpkg`(AUR)、`debhelper`(AUR)
（生成 .deb 时才要）、`wqy-microhei`（中文字体）、`python-requests`、`python-openpyxl`（内置小工具）、
`xdg-utils`（设默认打开方式）。

## 这个包做了什么额外的事

上游二进制是按 UOS（Debian 系）环境构建的，直接扔到 Arch 上有两处 ABI 不一致，这里都补掉了：

1. **Qt 6.8 → 6.12 符号缺口**
   上游二进制引用了 `QListView::eventFilter` 和 `QListView::mousePressEvent` 两个导出符号；
   Arch 的 Qt 6.12 已把这两个实现并进 `QAbstractItemView`，不再导出，直接运行会报
   `undefined symbol: _ZN9QListView11eventFilterEP7QObjectP6QEvent, version Qt_6`。
   仓库里的 `qt6-6.8-compat.cpp` 编译成 `libqt68compat.so`（符号版本节点 `Qt_6`），把这两个
   符号转发到基类的非虚实现，行为等价。装在 `/usr/lib/deepin-wine-builder/`，用
   `ld.so --preload` 只对本进程生效——不会污染 wine / dpkg / python 等子进程。

2. **`libyaml-cpp.so.0.7` 这个 SONAME**
   Arch 的 `yaml-cpp` 现在是 0.9，SONAME 变了。上游程序实际只用到
   `YAML::convert<bool>::decode` 一个符号，0.9 里也有。启动脚本在 `$XDG_RUNTIME_DIR` 下建一个
   `libyaml-cpp.so.0.7` → 现有实现的兼容软链，随 yaml-cpp 版本自动跟随。

另外：程序把资源路径写死成 `/opt/apps/deepin-wine-builder`，所以载荷必须装在 `/opt/apps`（这也是
namcap 报 `ELF files outside of a valid path ('opt/')` 的原因，无法避免）。`/usr/bin/deepin-wine-builder`
由裸软链换成了启动器脚本，DBus 激活文件也改成走启动器，否则 `--service` 模式会绕开兼容层。

## 已知限制

- **还不能真正跑 Windows 程序。** 上游还依赖 `deepin-wine10-stable`（UOS 的 wine 运行时）和
  `deepin-elf-verify`，这两个不在 Arch 仓库里，本仓库也还没打包。缺它们时 GUI、容器管理、
  打包流程能开，但启动应用会失败。需要完整功能建议走容器（distrobox + Deepin/UOS 镜像，
  在容器里 `apt` 装原版 deb，依赖由 apt 全解），或自行移植 `deepin-wine10-stable`。
- 包内的 `bin/batch_converter`、`bin/deps_search` 依赖 `deepin.runner.*` / `bottles.*` 这些
  UOS 侧的 python 模块，Arch 上没有，批量转换类功能会不可用。
- 上游是专有软件，见 `LICENSE`。本仓库只做再打包，不提供任何担保。
- 仅在 x86_64 上验证。

## 验证情况

打包者在 Arch（2026-11 快照，Qt 6.12 / dtk6 6.7.52）上验证：

- `makepkg` 构建通过，`namcap` 仅剩上面那条 `/opt` 路径提示；
- 把产出的包解到临时根、按真实安装路径（`/opt/apps`、`/usr/lib/deepin-wine-builder`、`/usr/bin`）
  运行，程序能完成初始化、注册 D-Bus 服务 `com.deepin.DeepinWineBuilder` 并稳定进入事件循环；
- 由于无头环境，**没有**验证真实窗口显示和 wine 容器创建，这两项需要在你自己的桌面上确认。

## 版本升级怎么做

`PKGBUILD` 里改三处：`pkgver`、`_debver`、`_debsha256`（`_deburl` 用 `_debver` 拼，通常不用动），
然后重新 `makepkg --printsrcinfo > .SRCINFO`。
