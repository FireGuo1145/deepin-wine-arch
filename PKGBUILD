# Maintainer: FireGuo <fireguo@localhost>
#
# 统信 UOS「Windows 应用兼容引擎」（deepin-wine-builder）及其 wine 运行时，
# 从 UOS 应用商店（Deepin 25 / UOS 25 官方源）的 Debian 包重新打包成 Arch 包。
#
# 一个 pkgbase 出 7 个包，仓库根目录一条命令即可全装：
#     makepkg -si
#
# 各包的「上游版本」写在各 pkgdesc 里；pkgver 是本仓库的快照日期——
# 因为 makepkg 不允许 split package 各自设 pkgver，而 7 个上游包的版本互不相同。
#
# 上游来源：https://com-store-packages.uniontech.com/appstore-V25
#           suite crimson / component appstore

pkgbase=deepin-wine
pkgname=(
  deepin-wine10-stable
  deepin-wine11-stable
  deepin-wine-staging
  deepin-wine-extras
  deepin-wine-helper
  deepin-wine-logtool
  deepin-wine-builder
)
pkgver=2026.11.08
pkgrel=1
arch=('x86_64')
url='https://www.uniontech.com/'
license=('LicenseRef-proprietary-UOS')
# 不 strip：上游 ELF 带 elfsign 校验和，改动会破坏 wine 自带工具的行为
options=('!strip')
makedepends=('curl' 'gcc')

# ---------------------------------------------------------------- 上游 deb 与校验
_deb10='deepin-wine10-stable_10.14deepin14_amd64.deb'
_sha10='dd5a9dc0c94ab7ce4d3ace543f1a8946c4c8b059cd1d2c23acbb83e6efc04018'
_deb11='deepin-wine11-stable_11.0deepin4+v25_amd64.deb'
_sha11='927c0e38932b0a5693cfdca53a15dfa72395b8e3f7db6d2b3a04a83523576ecf'
_debstg='deepin-wine-staging_11.0deepin10_amd64.deb'
_shastg='fb81b0c5d72de5dc1fe42413f530a762514535381ba29b79d2adc478de4dd38a'
_debext='deepin-wine-extras_1.0.2_all.deb'
_shaext='47794cd2df8ea9ce8dc2ddb4e06b4117e5b7bdda1b24a667d3844338882985ee'
_debhlp='deepin-wine-helper_5.4.12+v25-1_amd64.deb'
_shahlp='34549f17c05046cbdff5d3c8257079e3b87702bec799a6ba4bdf502108906671'
_deblog='deepin-wine-logtool_1.0.4_amd64.deb'
_shalog='5b95dc2eda4b1e78c786ab45ef6c47a0d7fd3f7b534a02e0fd5f528e17162ad8'
_debbld='deepin-wine-builder_4.0.2+v25-1_amd64.deb'
_shabld='e77846f5a9dc3de4a1823c7778d2627dc16671f4989e4c5f116146f5e6b830c5'

_debbase='https://com-store-packages.uniontech.com/appstore-V25/pool/appstore/d'

# ---------------------------------------------------------------------- 构建辅助
source=(
  'deepin-wine-builder.sh'
  'deepin-wine-builder.desktop'
  'deepin-wine-builder-debug.desktop'
  'com.deepin.DeepinWineBuilder.service'
  'deepin-wine-builder.svg'
  'qt6-6.8-compat.cpp'
  'qt6-6.8-compat.map'
  'dpkg-compat'
  'LICENSE'
)
sha256sums=(
  '3feb5f4eb308cce95381651b8963a393dfa07aed4f5c92ac318a9e14c9e0a5eb'   # deepin-wine-builder.sh
  '928bdb5c32b2c8d4e1b9f016a2d0f1db925c58730e144daa264c1565c42f1611'   # deepin-wine-builder.desktop
  '3bce07a1515107063a4248e872522cfa69558fd5df258822aebd0f8ad33e5106'   # deepin-wine-builder-debug.desktop
  '53a1f0a3458761d87bfe173f8022502748c769f34f66f22bdcadff142f68ac53'   # com.deepin.DeepinWineBuilder.service
  '82db47754a539aa626a0f5deb9a6a67ec6e6eb7b565d1bfb4a84a04091d1b810'   # deepin-wine-builder.svg
  '634fa6ddf46c841556c844f5bb01d2896b5977e913ac24d647130a549a55a4e4'   # qt6-6.8-compat.cpp
  'b2a3918cb91d791f31783a55d36f6f3e2a7fee32cdc7ac9087f42720d116dbd6'   # qt6-6.8-compat.map
  '259c6e097fec0407b62a42c34ab304f7b0a450c8741030cdc01c7d969b709480'   # dpkg-compat
  'f4ece7e8de81418341f6e27c097954066766eeb01f985f8f12e52caa0d807062'   # LICENSE
)

prepare() {
  cd "$srcdir"

  # 商店 CDN 有防盗链（缺 Referer 会 403），所以不能用 makepkg 内置下载器。
  # 已经手工下好 deb 的，放到本目录即可跳过下载。
  _fetch() {
    local name=$1 sha=$2
    if [[ ! -f $name ]]; then
      if [[ -f $startdir/$name ]]; then
        cp "$startdir/$name" .
      else
        msg2 "下载 $name"
        curl -fL --retry 3 --connect-timeout 20 \
             -A 'Mozilla/5.0 (X11; Linux x86_64)' \
             -e 'https://com-store-packages.uniontech.com/' \
             -o "$name" "$_debbase/${name%%_*}/$name"
      fi
    fi
    echo "$sha  $name" | sha256sum -c -
  }

  _fetch "$_deb10"  "$_sha10"
  _fetch "$_deb11"  "$_sha11"
  _fetch "$_debstg" "$_shastg"
  _fetch "$_debext" "$_shaext"
  _fetch "$_debhlp" "$_shahlp"
  _fetch "$_deblog" "$_shalog"
  _fetch "$_debbld" "$_shabld"
}

build() {
  cd "$srcdir"

  msg2 '不解包，仅编译 Qt 6.8 兼容 shim'
  mkdir -p qt68compat
  g++ -shared -fPIC -O2 -o qt68compat/libqt68compat.so qt6-6.8-compat.cpp \
      $(pkg-config --cflags --libs Qt6Widgets) \
      -Wl,--version-script="$srcdir/qt6-6.8-compat.map" \
      -Wl,-soname,libqt68compat.so
}

# 把某个 deb 的载荷直接解到 $pkgdir
_extract_deb() {
  local deb=$1 tmp
  tmp=$(mktemp -d)
  bsdtar -xf "$srcdir/$deb" -C "$tmp" --no-same-owner 2>/dev/null
  local payload
  payload=$(find "$tmp" -maxdepth 1 -name 'data.tar.*' | head -1)
  install -d "$pkgdir"
  bsdtar -xf "$payload" -C "$pkgdir" --no-same-owner --no-xattrs
  rm -rf "$tmp"
  rm -rf "$pkgdir/usr/share/doc" "$pkgdir/usr/share/lintian"
  install -Dm644 "$srcdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

# ------------------------------------------------------------------- wine 运行时
_WINE_OPT=(
  'alsa-lib: 声音输出（运行时 dlopen，缺了只是没声音）'
  'libpulse: PulseAudio 后端'
  'libgstreamer: 媒体播放'
  'gst-plugins-base: 媒体播放'
  'libgphoto2: 数码相机透传'
  'pcsclite: 智能卡'
  'sane: 扫描仪'
  'libusb: USB 设备透传'
  'ocl-icd: OpenCL'
  'libcups: 打印'
  'fontconfig: 字体渲染'
  'freetype2: 字体渲染'
  'libpng: 图像'
  'libjpeg-turbo: 图像'
  'gnutls: 网络加密'
  'krb5: 域认证'
  'vulkan-icd-loader: DXVK / VKD3D 需要'
  'sdl2: 游戏手柄等'
  'libv4l: 摄像头'
  'libxcomposite: 窗口合成（dlopen）'
  'libxcursor: 鼠标指针（dlopen）'
  'libxfixes: X11 扩展（dlopen）'
  'libxi: 输入设备（dlopen）'
  'libxinerama: 多显示器（dlopen）'
  'libxrandr: 分辨率（dlopen）'
  'libxrender: 渲染（dlopen）'
  'libxxf86vm: 显示模式（dlopen）'
  'libxext: X11 扩展（dlopen）'
)

package_deepin-wine10-stable() {
  pkgdesc='deepin-wine 10 运行时（上游 10.14deepin14，纯 wow64，无需 multilib）'
  depends=('glibc')
  optdepends=("${_WINE_OPT[@]}")
  _extract_deb "$_deb10"
}

package_deepin-wine11-stable() {
  pkgdesc='deepin-wine 11 运行时（上游 11.0deepin4+v25，纯 wow64，无需 multilib）'
  depends=('glibc')
  optdepends=("${_WINE_OPT[@]}")
  _extract_deb "$_deb11"
}

package_deepin-wine-staging() {
  pkgdesc='deepin-wine staging 运行时（上游 11.0deepin10，纯 wow64，无需 multilib）'
  depends=('glibc')
  optdepends=("${_WINE_OPT[@]}")
  _extract_deb "$_debstg"
}

package_deepin-wine-extras() {
  pkgdesc='deepin-wine 附加组件 DXVK / VKD3D（上游 1.0.2）'
  arch=('any')
  depends=('glibc')
  optdepends=(
    'vulkan-icd-loader: DXVK / VKD3D 运行需要 Vulkan 加载器'
    'vulkan-radeon: AMD 显卡的 Vulkan 驱动'
    'vulkan-intel: Intel 显卡的 Vulkan 驱动'
    'nvidia-utils: NVIDIA 显卡的 Vulkan 驱动'
  )
  _extract_deb "$_debext"
}

package_deepin-wine-helper() {
  pkgdesc='deepin-wine 运行辅助工具 /opt/deepinwine/tools（上游 5.4.12+v25-1）'
  depends=(
    'glibc' 'gcc-libs'
    'qt6-base'
    'dtk6core' 'dtk6gui' 'dtk6widget'
    'libx11'
    'mesa'                     # libGL.so.1，gl-wine64 需要
    'deepin-qt6integration'    # chameleon 风格插件，DTK 界面缺了会崩
  )
  optdepends=(
    'p7zip: 解压安装包（上游依赖 p7zip-full）'
    'python-dbus: 托盘/菜单相关脚本（上游依赖 python3-dbus）'
    'noto-fonts-cjk: 中文字体（上游依赖 fonts-noto-cjk）'
    'xorg-xdpyinfo: 上游依赖 x11-utils'
  )
  _extract_deb "$_debhlp"
}

package_deepin-wine-logtool() {
  pkgdesc='deepin-wine 日志采集工具（上游 1.0.4）'
  depends=('glibc')
  optdepends=('dconf: 读取 dconf 配置（上游依赖 dconf-cli）')
  _extract_deb "$_deblog"
}

# ------------------------------------------------------------------- 主程序
package_deepin-wine-builder() {
  pkgdesc='统信 Windows 应用兼容引擎（上游 4.0.2+v25-1）'
  depends=(
    'glibc' 'gcc-libs'
    'qt6-base' 'qt6-5compat' 'qt6-declarative'
    'dtk6core' 'dtk6gui' 'dtk6widget' 'dtk6log'
    # 提供 Qt 的 chameleon 风格插件（即 Dtk::Widget::DStyle）。
    # 缺了它 QStyleFactory::create("chameleon") 会退回 Fusion，
    # 程序里 qobject_cast<QProxyStyle *>(widget->style()) 拿到空指针随即崩溃。
    'deepin-qt6integration'
    'libarchive' 'yaml-cpp' 'vulkan-icd-loader' 'libx11'
    'python'
    'hicolor-icon-theme'
    'deepin-wine10-stable'
    'deepin-wine-helper'
  )
  optdepends=(
    'deepin-wine11-stable: 另一套 wine 11 运行时（可在界面里切换）'
    'deepin-wine-staging: wine-staging 运行时（可在界面里切换）'
    'deepin-wine-extras: DXVK / VKD3D 等附加组件与离线依赖包'
    'deepin-wine-logtool: 与 builder 配套的日志采集工具'
    'unrar: 解包 RAR 格式的 Windows 安装包'
    'cabextract: 解包 CAB 格式的安装包'
    'wqy-microhei: 中文界面字体'
    'fakeroot: 打包 .deb 时需要'
    'dpkg: AUR —— 生成 .deb 安装包需要 dpkg-deb'
    'debhelper: AUR —— 生成 Debian 打包脚手架时需要'
    'xdg-utils: 设置默认 MIME 关联时需要'
    'python-requests: 内置 AI 截图分析工具（appdata/tools）需要'
    'python-openpyxl: 内置 yml 测试脚本需要'
    'deepin-qt6platform-plugins: 需要 dxcb 平台插件或 DDE 窗口装饰时才装'
  )
  provides=('deepin-wine-runner')
  conflicts=('deepin-wine-runner')
  replaces=('deepin-wine-runner')
  install=deepin-wine-builder.install

  _extract_deb "$_debbld"

  # 程序把资源路径写死成 /opt/apps/deepin-wine-builder，载荷已在上面解好。
  # deb 自带的 /usr/bin/deepin-wine-builder 是条裸软链，换成带兼容层的启动器
  rm -f "$pkgdir/usr/bin/deepin-wine-builder"
  install -Dm755 "$srcdir/deepin-wine-builder.sh" "$pkgdir/usr/bin/deepin-wine-builder"

  # 桌面项、DBus 激活、MIME 定义、图标
  install -Dm644 "$srcdir/deepin-wine-builder.desktop" \
    "$pkgdir/usr/share/applications/deepin-wine-builder.desktop"
  install -Dm644 "$srcdir/deepin-wine-builder-debug.desktop" \
    "$pkgdir/usr/share/applications/deepin-wine-builder-debug.desktop"
  install -Dm644 "$srcdir/com.deepin.DeepinWineBuilder.service" \
    "$pkgdir/usr/share/dbus-1/services/com.deepin.DeepinWineBuilder.service"
  install -Dm644 "$pkgdir/opt/apps/deepin-wine-builder/entries/mime/packages/deepin-wine-builder.xml" \
    "$pkgdir/usr/share/mime/packages/deepin-wine-builder.xml"
  install -Dm644 "$srcdir/deepin-wine-builder.svg" \
    "$pkgdir/usr/share/icons/hicolor/scalable/apps/deepin-wine-builder.svg"

  # Qt 6.8 兼容 shim 放私有目录，避免污染全局符号空间
  install -d "$pkgdir/usr/lib/deepin-wine-builder"
  install -m755 "$srcdir/qt68compat/libqt68compat.so" \
    "$pkgdir/usr/lib/deepin-wine-builder/libqt68compat.so"

  # dpkg / dpkg-query 兼容层（不落 /usr/bin，避免影响系统里真正的 dpkg）
  install -Dm755 "$srcdir/dpkg-compat" "$pkgdir/usr/lib/deepin-wine-builder/compat-bin/dpkg"
  ln -s dpkg "$pkgdir/usr/lib/deepin-wine-builder/compat-bin/dpkg-query"
}
