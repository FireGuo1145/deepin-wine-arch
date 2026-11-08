# deepin-wine 的 Arch 打包仓库

把统信 UOS 应用商店里的 **deepin-wine-builder**（统信 Windows 应用兼容引擎，提供并替代
`deepin-wine-runner`）以及它要用到的 **wine 运行时**，从 Debian 包重新打包成 pacman 能装的形式。

上游全部来自 `https://com-store-packages.uniontech.com/appstore-V25`（suite `crimson`，
component `appstore`），也就是 Deepin 25 / UOS 25 官方的商店源。

## 包一览

| 目录 | 包 | 版本 | 说明 |
| --- | --- | --- | --- |
| `deepin-wine10-stable/` | `deepin-wine10-stable` | 10.14deepin14 | wine 10 运行时，builder 的硬依赖 |
| `deepin-wine-builder/` | `deepin-wine-builder` | 4.0.2+v25-1 | 主程序（Qt6 + DTK6 图形界面） |
| `deepin-wine-extras/` | `deepin-wine-extras` | 1.0.2 | DXVK / VKD3D 等附加组件 |
| `deepin-wine11-stable/` | `deepin-wine11-stable` | 11.0deepin4+v25 | wine 11 运行时（可选） |
| `deepin-wine-staging/` | `deepin-wine-staging` | 11.0deepin10 | wine-staging 运行时（可选） |
| `deepin-wine-logtool/` | `deepin-wine-logtool` | 1.0.4 | 配套日志采集 CLI（可选） |

## 安装

推荐直接用脚本（先 `makepkg` 构建，再 `pacman -U` 安装；不需要 root 跑 makepkg）：

```bash
git clone <本仓库地址> deepin-wine-arch && cd deepin-wine-arch
./install-all.sh            # 装 wine10 + extras + builder
./install-all.sh --all      # 连 wine11 / staging / logtool 一起装
```

手工装也行，按依赖顺序逐个来：

```bash
cd deepin-wine10-stable && makepkg -si && cd ..
cd deepin-wine-extras    && makepkg -si && cd ..
cd deepin-wine-builder   && makepkg -si && cd ..
```

卸载：`sudo pacman -Rns deepin-wine-builder deepin-wine-extras deepin-wine10-stable`

## 下载说明

商店 CDN 有防盗链，裸请求会 307 跳转到 `app-store-files.uniontech.com` 再返回 403
（必须带 `Referer`）。所以每个 PKGBUILD 的 `prepare()` 里用 `curl` 带 UA + Referer 下载，
再用写死的 SHA256 校验，没法交给 makepkg 内置下载器。

如果已经手工下好 deb，把它放到对应包目录里，`prepare()` 会直接复用并校验 SHA256。

## 打包时补的 Arch 兼容层

上游二进制是按 UOS（Debian 系 + Qt 6.8）构建的，直接扔到 Arch 上有两处 ABI 不一致，都在
`deepin-wine-builder` 包里补掉了：

1. **Qt 6.8 → 6.12 符号缺口**：上游引用了 `QListView::eventFilter` /
   `QListView::mousePressEvent` 两个导出符号，Arch 的 Qt 6.12 已把它们并进
   `QAbstractItemView` 不再导出（否则报 `undefined symbol … version Qt_6`）。
   `qt6-6.8-compat.cpp` 编译成 `libqt68compat.so`（符号版本节点 `Qt_6`），把这两个符号
   转发到基类非虚实现。装在 `/usr/lib/deepin-wine-builder/`，用 `ld.so --preload` 注入，
   只作用于本进程——不会污染 wine / dpkg / python 等子进程。
2. **`libyaml-cpp.so.0.7`**：Arch 的 `yaml-cpp` 已是 0.9。上游只用到
   `YAML::convert<bool>::decode` 一个符号，0.9 里也有；启动器在 `$XDG_RUNTIME_DIR` 下建一个
   `libyaml-cpp.so.0.7` 兼容软链，随 Arch 的 yaml-cpp 版本自动跟随。

另外程序把资源路径写死成 `/opt/apps/deepin-wine-builder`，所以载荷必须装在 `/opt/apps`，
`/usr/bin/deepin-wine-builder` 由裸软链换成了启动器脚本，DBus 激活文件也改成走启动器。

## 关于依赖

- **wine 本体只硬依赖 glibc。** 图形/声音/设备相关的库（libasound、libgphoto2、libpcsclite、
  libsane、gstreamer、vulkan…）都是运行时 `dlopen`，所以在上游 deb 里是 `Depends` 的东西，
  这里按 `optdepends` 处理：缺哪个只是对应功能不可用，不会启动失败。
- **不需要 multilib。** 上游 wine 是纯 amd64 构建 + wow64 模拟，包内 `i386-windows` 里只有
  PE 文件，全是 64 位 ELF，因此不用装 `lib32-*`。
- 上游 `Depends: deepin-elf-verify`，但这个包在 Deepin 25 的源里根本不存在、官方的
  Deepin 25 虚拟机里也没装，wine 照样正常工作——所以这里没有打包它。
- 界面的「生成 .deb 安装包」功能需要 `dpkg` 和 `debhelper`，这两个在 AUR，归入 `optdepends`。

## 验证情况

在 Arch（2026-11 快照，Qt 6.12 / dtk6 6.7.52，无 multilib）上，用构建产物的**真实安装布局**
（解包后按 `/opt`、`/usr/bin`、`/usr/lib` 叠加运行）验证：

- `deepin-wine10-stable --version` → `wine-10.14`
- `wineboot -u` 成功建出 prefix：`drive_c` 22 MB、`system32` 588 个 dll
- `wine cmd /c "echo WINE_EXEC_OK"` → 正常输出，说明 PE 执行链路通
- `deepin-wine-builder` 能完成初始化、注册 D-Bus 服务 `com.deepin.DeepinWineBuilder` 并稳定
  进入事件循环；`makepkg` 全部 6 个包构建通过，`namcap` 仅剩
  `ELF files outside of a valid path ('opt/')`（`/opt/apps` 是程序硬编码路径，无法避免）

**没有验证**的：真实桌面窗口显示（构建环境无显示器/会话总线）、通过界面装一个真实的
Windows 安装包、DXVK 在具体显卡上的表现。这些要在你自己的机器上过一遍。

## 已知限制

- 包内的 `bin/batch_converter`、`bin/deps_search` 依赖 `deepin.runner.*` / `bottles.*`
  这些 UOS 侧 Python 模块，Arch 上没有，批量转换类功能不可用。
- `deepin-wine-runtime`（带 exagear 的 i386 运行时，218 MB）和 `deepin-wine-helper`
  没有打包，builder 的主要流程用不到它们。
- 上游是专有软件，见各包目录下的 `LICENSE`。本仓库只做再打包，不提供担保。
- 只在 x86_64 上验证。

## 升级某个包

改对应目录 PKGBUILD 里的 `pkgver` / `_debname` / `_debsha256`，然后：

```bash
cd <包目录> && makepkg --printsrcinfo > .SRCINFO
```

`_deburl` 是用包名和 `_debname` 拼的，一般不用动。
