# deepin-wine —— Arch Linux 打包仓库

把统信 UOS「Windows 应用兼容引擎」（`deepin-wine-builder`，即 `deepin-wine-runner` 的替代品）
和它用到的整套 wine 运行时，从 UOS/Deepin 官方商店源的 Debian 包重新打包成 Arch 包。

**一个仓库，一条命令装全套：**

```bash
git clone <本仓库地址> deepin-wine && cd deepin-wine
makepkg -si
```

`makepkg -si` 会构建并安装下面 7 个包（`-s` 自动补装 `dtk6*`、`qt6-*` 等仓库依赖，
`-i` 一次性把所有包交给 pacman 安装，包之间的依赖在同一个事务里满足）。

## 包含的包

| 包 | 上游版本 | 装了什么 |
| --- | --- | --- |
| `deepin-wine10-stable` | 10.14deepin14 | wine 10 运行时 → `/opt/deepin-wine10-stable` |
| `deepin-wine11-stable` | 11.0deepin4+v25 | wine 11 运行时 |
| `deepin-wine-staging` | 11.0deepin10 | wine-staging 运行时 |
| `deepin-wine-extras` | 1.0.2 | DXVK / VKD3D 等附加组件 → `/opt/deepin/deepin-wine-builder/additions` |
| `deepin-wine-helper` | 5.4.12+v25-1 | `/opt/deepinwine/tools/*`（run_v4.sh、sendkeys、startbottle.exe、gl-wine…） |
| `deepin-wine-logtool` | 1.0.4 | 日志采集 CLI |
| `deepin-wine-builder` | 4.0.2+v25-1 | 主程序（Qt6 + DTK6 图形界面） |

`pkgver` 是本仓库的快照日期（`2026.11.08`）：makepkg 不允许 split package 各自设版本号，
而这 7 个上游包版本互不相同，所以把各自的「上游版本」写在 `pkgdesc` 里，并在 `PKGBUILD`
中用 `_deb10` / `_deb11` … 这些变量 + 逐包 SHA256 钉死来源。

## 下载说明

商店 CDN 有防盗链，裸请求会 307 跳到 `app-store-files.uniontech.com` 再 403（必须带
`Referer`），所以没法用 makepkg 内置下载器。`prepare()` 里用 `curl` 带 UA + Referer 下载，
再用写死的 SHA256 校验。

已经手工下好 deb 的，把文件放到仓库根目录即可跳过下载（文件名见 `PKGBUILD` 里的 `_deb*`）。

- 上游源：`https://com-store-packages.uniontech.com/appstore-V25`（suite `crimson`，component `appstore`）

## 打包时补的 Arch 兼容层（都是踩过的坑）

1. **`QListView::eventFilter` / `mousePressEvent` 符号缺失**
   上游二进制由 UOS 的 Qt 6.8 构建，引用了这两个导出符号；Arch 的 Qt 6.12 已把它们并进
   `QAbstractItemView`，直接运行会报 `undefined symbol … version Qt_6`。
   `qt6-6.8-compat.cpp` 编译成 `libqt68compat.so`（符号版本节点 `Qt_6`），转发到基类非虚实现，
   装在 `/usr/lib/deepin-wine-builder/`，用 `ld.so --preload` 注入——只作用于本进程，
   不会污染 wine / dpkg / python 等子进程。

2. **`libyaml-cpp.so.0.7` 这个 SONAME**
   Arch 的 `yaml-cpp` 已是 0.9。上游只用到 `YAML::convert<bool>::decode` 一个符号，0.9 里也有；
   启动器在 `$XDG_RUNTIME_DIR` 下建兼容软链，随 yaml-cpp 版本自动跟随。

3. **缺 `chameleon` 风格插件 → 启动即 Segmentation fault**
   程序绘制代码里有 `qobject_cast<QProxyStyle *>(widget->style())->proxy()`，它假设风格是
   DTK 的 `DStyle`。而 `chameleon` 风格插件由 `deepin-qt6integration` 提供，没装时
   `QStyleFactory::create("chameleon")` 会静默退回 `QFusionStyle`，cast 得到 NULL，一画界面就崩。
   所以 `deepin-wine-builder` 硬依赖 `deepin-qt6integration`（它还提供 DCI/DSVG 图标引擎）。

4. **依赖检查走 dpkg → 应用误报「缺 deepin-wine10-stable」**
   builder 和它管理的应用包判断依赖用的是 `dpkg -s <pkg>` / `dpkg-query -W`。Arch 上没有 dpkg，
   查询一律失败，于是即使 wine10 已装好也报缺。
   包内自带 `dpkg-compat`，装成 `/usr/lib/deepin-wine-builder/compat-bin/{dpkg,dpkg-query}`，
   只在启动器的 `PATH` 里生效（不碰系统真 dpkg）：
   - Debian 包名 → Arch 包名映射，用 pacman 数据库如实回答（`libglx-mesa0`→`mesa`、
     `libqt6core6`→`qt6-base`、`libasound2`→`alsa-lib`…）
   - 上游虚依赖 `libcapi20-3`、`deepin-elf-verify` 按已满足处理
   - 用 `bsdtar` 实现 `dpkg -x`，应用自带离线 deb 也能解开

5. **`/opt/apps/deepin-wine-builder` 是硬编码路径**，载荷必须装在这里（这也是 namcap 会报
   `ELF files outside of a valid path ('opt/')` 的原因，无法避免）。`/usr/bin/deepin-wine-builder`
   由裸软链换成了启动器脚本，DBus 激活也改成走启动器。

## 依赖取舍

- **wine 本体只硬依赖 glibc。** 图形/声音/设备库（libasound、libgphoto2、libpcsclite、libsane、
  gstreamer、vulkan…）都是运行时 `dlopen`，所以在上游 deb 里是 `Depends` 的东西这里按
  `optdepends` 处理：缺哪个只是对应功能不可用，不会启动失败。
- **不需要 multilib。** 上游 wine 是纯 amd64 + wow64 构建，包内 `i386-windows` 里全是 PE 文件，
  没有任何 32 位 ELF。
- 上游 `Depends: deepin-elf-verify` 是虚的：该包在 Deepin 25 源里根本不存在、官方虚拟机也没装，
  wine 照样正常，所以没打包。
- 「生成 .deb 安装包」功能需要 `dpkg` 和 `debhelper`（都在 AUR），归入 `optdepends`。

## 验证情况

在 Arch（2026-11 快照，Qt 6.12 / dtk6 6.7.52，无 multilib）上：

- 仓库根目录一条 `makepkg` 出全部 7 个包，`namcap` 仅剩 `/opt` 路径那条提示
- `deepin-wine10-stable --version` → `wine-10.14`
- `wineboot -u` 建出 prefix：`drive_c` 22 MB、`system32` 588 个 dll
- `wine cmd /c "echo WINE_EXEC_OK"` 正常输出，PE 执行链路通
- `deepin-wine-builder` 能初始化、注册 D-Bus `com.deepin.DeepinWineBuilder` 并稳定进入事件循环；
  启动时会 `dpkg -s libglx-mesa0`，兼容层回答「已安装」
- 包内 `dpkg-compat`：`dpkg -s deepin-wine10-stable` / `libglx-mesa0` 返回已安装，
  未打包的包如实返回未安装

**没验证**的：真实桌面窗口的观感、通过界面装一个真实的 Windows 安装包、DXVK 在具体显卡上的
表现、以及应用级依赖检查（需要在界面上点开某个应用才会触发）。这些要在你自己的机器上过一遍。

## 排错

启动即 `Segmentation fault (core dumped)`：

```bash
# 1) 确认 deepin-qt6integration 装了（缺 chameleon 插件必崩）
pacman -Q deepin-qt6integration

# 2) 抓栈
gdb -q -batch -ex run -ex "bt 15" --args \
  /usr/lib/ld-linux-x86-64.so.2 --preload /usr/lib/deepin-wine-builder/libqt68compat.so \
  /opt/apps/deepin-wine-builder/files/bin/deepin-wine-builder

# 3) 程序日志
tail -50 ~/.cache/deepin/deepin-wine-builder/deepin-wine-builder.log
```

Wayland 下如果仍有异常，可退回 XWayland 试试：`QT_QPA_PLATFORM=xcb deepin-wine-builder`。

## 升级某个组件

1. 改 `PKGBUILD` 里对应组件的 `_deb*`（文件名）和 `_sha*`（SHA256）；
2. 把 `pkgver` 更新为新的快照日期（例如 `2026.12.01`）；
3. `makepkg --printsrcinfo > .SRCINFO`。

## 版权

上游是统信软件的专有软件，见 `LICENSE`。本仓库只做再打包与兼容层，不提供任何担保。
