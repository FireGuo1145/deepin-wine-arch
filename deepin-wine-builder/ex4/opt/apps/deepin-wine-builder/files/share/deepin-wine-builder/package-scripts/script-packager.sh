#!/bin/bash
clean_bottle_cmd="deepin-wine10-stable"

version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

try_cmd_exit()
{
    "$@"
    if [ $? != 0 ];then
        echo "$@ failed"
        exit 1
    fi
}

CheckTool()
{
    a=$(which $1)
    if [ $? -ne 0 ]
    then
        echo "missing $1, need to install package \"$2\""
        exit
    fi
}
CheckParamE()
{
    if [ -z "$1" ]
    then
        echo "$2"
        exit 1
    fi
}
CheckPathExists()
{
    if [ ! -d "$1" ]
    then
        echo "$2"
        exit 1
    fi
}


Check_icons()
{
    local icon_dir="$package_workdir/icons"

    if [ ! -d "$icon_dir" ];then
        mkdir -p $icon_dir/hicolor/48x48/apps
        mkdir -p $icon_dir/hicolor/16x16/apps
        mkdir -p $icon_dir/hicolor/64x64/apps
        mkdir -p $icon_dir/hicolor/128x128/apps
        mkdir -p $icon_dir/hicolor/32x32/apps
    fi
    if [[ -n $(find $icon_dir/*/*/apps -name ${1}.svg) ]];then
        echo "${1}.svg"
    elif [[ -n $(find $icon_dir/*/*/apps -name ${1}.png) ]];then
        echo "${1}.png"
    else
        exit 1
    fi
}

CheckArchEnv()
{
    if [ -n "$enable_package_i386" ]&&[ $enable_package_i386 -eq 1 ] ;then
        if [ -z "$SPECIFY_SHELL_PATH_i386" ]||[ -z "$package_depends_i386" ]||[ -z "$apprun_cmd_i386" ]; then
            echo "<===== 变量SPECIFY_SHELL_PATH_i386 | package_depends_i386 | apprun_cmd_i386 都不能为空！！！"
            exit 1
        fi
        test -n "$apprun_cmd_i386" && clean_bottle_cmd="$apprun_cmd_i386"
    fi

    if [ -n "$enable_package_amd64" ]&&[ $enable_package_amd64 -eq 1 ] ;then
        if [ -z "$SPECIFY_SHELL_PATH_amd64" ]||[ -z "$package_depends_amd64" ]||[ -z "$apprun_cmd_amd64" ]; then
            echo "<===== 变量SPECIFY_SHELL_PATH_amd64 | package_depends_amd64 | apprun_cmd_amd64 都不能为空！！！"
            exit 1
        fi
        test -n "$apprun_cmd_amd64" && clean_bottle_cmd="$apprun_cmd_amd64"
    fi

    if [ -n "$enable_package_arm64" ]&&[ $enable_package_arm64 -eq 1 ] ;then
        if [ -z "$SPECIFY_SHELL_PATH_ARM64" ]||[ -z "$package_depends_arm64" ]||[ -z "$apprun_cmd_arm64" ]; then
            echo "<===== 变量SPECIFY_SHELL_PATH_ARM64 | package_depends_arm64 | apprun_cmd_arm64 都不能为空！！！"
            exit 1
        fi
        test -n "$apprun_cmd_arm64" && clean_bottle_cmd="$apprun_cmd_arm64"
    fi

    if [ -n "$enable_package_loongarch64" ]&&[ $enable_package_loongarch64 -eq 1 ] ;then
        if [ -z "$SPECIFY_SHELL_PATH_loongarch64" ]||[ -z "$package_depends_loongarch64" ]||[ -z "$apprun_cmd_loongarch64" ]; then
            echo "<===== 变量SPECIFY_SHELL_PATH_loongarch64 | package_depends_loongarch64 | apprun_cmd_loongarch64 都不能为空！！！"
            exit 1
        fi
        test -n "$apprun_cmd_loongarch64" && clean_bottle_cmd="$apprun_cmd_loongarch64"
    fi
}

CheckBottle()
{
    if [ ! -f "$1/user.reg" ];then
        echo "$1 不是wine容器"
        exit
    fi

    link_arrays=("dosdevices/z:" "drive_c/users/$USER/Desktop" "drive_c/users/$USER/My Documents" "drive_c/users/$USER/Documents" "drive_c/users/$USER/Music" "drive_c/users/$USER/Pictures" "drive_c/users/$USER/Videos" "drive_c/users/$USER/Downloads")
    for link_path in "${link_arrays[@]}" ; do
        if [ ! -L "$1/$link_path" ] && [ -d "$1/$link_path" ];then
            echo "$1/$link_path 不是软连接"
            rm -fr "$1/$link_path"
        fi
    done
}

CheckTool "fakeroot" "fakeroot"
CheckTool "dh_testdir" "debhelper"
CheckTool "7z" "p7zip-full"

CheckParamE "$app_description" "App description not given"
#CheckParamE "$desktop_file_categories" "Categories of desktop file not given"
#CheckParamE "$desktop_file_icon" "Icon file of desktop file not given"
if [ -z "$deb_entries_dir" ]; then
    CheckParamE "$app_name" "App name not given"
    CheckParamE "$app_name_zh_cn" "App zh-cn name not given"
    CheckParamE "$desktop_file_main_exe" "Main exe filename not given
    ===>Wine set this value to WMClass of app window, Dock/Launcher need this for matching"
fi
CheckParamE "$deb_package_name" "Package name not given"
CheckParamE "$deb_version_string" "Package version not given"
CheckArchEnv

if [ "$old_package_name" == "$deb_package_name" ];then
    echo "old_package_name 不能和deb_package_name一致"
    exit
fi

if [ -z "$public_bottle_name" ];then
    export public_bottle_name="$deb_package_name"
fi

BottlePath="$HOME/.deepinwine/bottles/$public_bottle_name"
use_last_bottle="$1"

#Replace USER value to string
export EXEC_PATH=$(echo "$exec_path" | sed -e "s/$USER/\$USER/g")

if [ -z "$deb_packager" ];then 
   export deb_packager="Deepin WINE Team";
fi
if [ -z "$deb_packager_email" ];then deb_packager_email="penghao@linuxdeepin.com";fi
if [ -z "$deb_date" ];then deb_date=`date -R`;fi

echo "+++++ Empire Starts here. +++++"
echo "app description:     $app_description"
echo "app name:            $app_name"
echo "app name zh-cn:      $app_name_zh_cn"
echo "date:                $deb_date"
echo "deb package name:    $deb_package_name"
echo "deb packager:        $deb_packager"
echo "packager email:      $deb_packager_email"
echo "version:             $deb_version_string"
echo "deb release type     $deb_release_type"
echo "yml path             $yml_url"
echo "deb entries dir:     $deb_entries_dir"
echo "app categories:      $desktop_file_categories"
echo "desktop icon:        $desktop_file_icon"
echo "app main executable: $desktop_file_main_exe"
echo "origin bottle name:  $origin_bottle_name"
echo "public bottle name:  $public_bottle_name"
echo "old package name:    $old_package_name"
echo "package depends:     $package_depends"
echo "mime type:           $mime_type"
echo "activex name:        $activex_name"
echo "bottle path:         $BottlePath"
echo "make autostart:      $make_autostart"
echo "send to desktop:     $send_to_desktop"
echo "exec file path:      $EXEC_PATH"

curdir=$(dirname $0)
package_workdir="$HOME/.cache/deepin-wine-builder/"
stgdir="$package_workdir/staging.dir"
dstdir="$package_workdir/final.dir"
outdir="$dstdir/opt/apps/$deb_package_name"
outentries="$outdir/entries"
outfiles="$outdir/files"
run_sh_dir="/opt/apps/$deb_package_name/files"
uos_package_save="$package_workdir/package_save/uos"
echo "DEB_SAVE_DIR: $DEB_SAVE_DIR"
if [ -d "$DEB_SAVE_DIR" ];then
    uos_package_save="$DEB_SAVE_DIR"
fi

patch_dll_path=$run_sh_dir/dlls

CheckPathExists "$curdir/debian"            "debian package building scripts lost."
CheckPathExists "$curdir/template"          "package template scripts lost."

echo "=====>Preparing packaging environment..."
mkdir -p "$package_workdir"

if [ -d "$stgdir" ]; then rm -rf "$stgdir"; fi
if [ -d "$dstdir" ]; then rm -rf "$dstdir"; fi
mkdir -p "$dstdir"
mkdir -p "$outentries"
mkdir -p "$outfiles"
if [ ! -d "$uos_package_save" ]; then mkdir -p "$uos_package_save"; fi

echo "<=====done."

# helper架构改为arm64和amd64,脚本代码统一
HELPER_MIN_VER="5.2.4"
# ARM版本wine依赖改为deepin-emu-tool
ARM_WINE_MIN_VER="6.0.0.51-2"
X86_WINE_MIN_VER="6.0.0.51-1"
# loongarch版本deepin-wine和helper没有跟随主线更新，版本不能写高了
LOONGARCH_HELPER_MAX_VER="5.1.31-2"
LOONGARCH_WINE_MAX_VER="6.0.0.19-1"

if [ -f "$1" ];then
    pkgname=$(dpkg -I "$1" | grep Package: | awk '{print $NF}')
    if [ "$pkgname" = "$deb_package_name" ];then
        echo "Use $1 to package"
        dpkg -x "$1" "$dstdir"
        unset USE_PACKAGE_DLLS
        use_last_bottle=""
        read -p "修改 $dstdir 目录之后回车继续打包"
    fi
fi

# 如果指定了 entries 文件夹，直接使用该文件夹下的图标
if [[ -d "$deb_entries_dir" ]]; then
    cp -r "$deb_entries_dir"/icons "$outentries"
else
    # 优先用环境变量指定的图标
    if [ -f "$icon_file" ]; then
        find "$package_workdir/icons" -name  ${deb_package_name}* | xargs -i rm {}
        if [ ! -d "$package_workdir/icons/hicolor/48x48/apps" ];then
            mkdir -p "$package_workdir"/icons/hicolor/48x48/apps
        fi
        cp "$icon_file" "$package_workdir"/icons/hicolor/48x48/apps/
    fi

    export desktop_file_icon=$(Check_icons $deb_package_name)
    if [ -n "$desktop_file_categories" ] && [ -z "$desktop_file_icon" ]; then
        if [ -n "$1" ] && [ -d "/opt/apps/$deb_package_name/entries/icons" ]; then
            echo "cp icon from /opt/apps/$deb_package_name/entries/icons"
            iconpath=$(pwd)
            cd "/opt/apps/$deb_package_name/entries/icons"
            find -iname "$deb_package_name"* -exec cp "{}" "$iconpath/icons/{}" \;
            cd -
        elif [ -f "$1" ] && [ -z "$use_last_bottle" ]; then
            iconpath=$(pwd)
            cd "$dstdir/opt/apps/$deb_package_name/entries/icons"
            find -iname "$deb_package_name"* -exec cp "{}" "$iconpath/icons/{}" \;
            cd -
        else
            echo "make icon form PE file"
            $curdir/mkicons.sh
        fi
    fi
    export desktop_file_icon=$(Check_icons $deb_package_name)
    if [ -n "$desktop_file_categories" ] && [ -z "$desktop_file_icon" ]; then
        echo "没找到图标"
        exit
    fi
fi

if [ -n "$USE_PACKAGE_DLLS" ] && [ -d "$patch_dll_path" ];then
    cp -r --preserve=timestamp "$patch_dll_path" "$outfiles/"
    echo "===========copy patch dlls==============="
    ls "$patch_dll_path" -alh
    echo "=========================================="
fi

WIN_FONTS=$(ls "$BottlePath/drive_c/windows/Fonts")
if [ -n "$WIN_FONTS" ];then
    echo ""
    echo "容器中打包了如下字体: $WIN_FONTS。请确认这些字体没有侵犯版权，否则会有法律风险!"
fi

[ -z "$deb_package_specified_path" ] && deb_package_specified_path="$curdir/specified"

if [ -n "$PROGRAM_INDEX_NAME" ];then
    specified_dir="$deb_package_specified_path/$PROGRAM_INDEX_NAME"
else
    specified_dir="$deb_package_specified_path/$deb_package_name"
fi

if [ -d "$specified_dir/root/" ]; then
    echo "copy root files.."
    cp -ruv $specified_dir/root/* "$dstdir"
fi

if [ "$deb_release_type" == "release_yml_deb" ] && [ -f "$yml_url" ]; then
    cp "$yml_url" "$outfiles/installer.yml"
elif [ -n "$use_last_bottle" ] && [ -f "/opt/apps/$deb_package_name/files/files.7z" ]; then
    echo "Use last bottle file"
    cp /opt/apps/$deb_package_name/files/files.7z "$outfiles/"
elif [ ! -f "$outfiles/files.7z" ];then
    CheckPathExists "$BottlePath" "Original bottle do NOT exist."

    echo "=====>Clean bottle..."
    ${curdir}/cleanbottle.sh $BottlePath $clean_bottle_cmd
    CheckBottle "$BottlePath"
    echo "<=====done."

    echo "=====>Creating program files archive..."
    mv "$BottlePath" "$stgdir"
    ${curdir}/fixbottle.sh "$stgdir" $deb_package_name
    # Dir links in profile should been recreated when deploy.
    find "$stgdir/drive_c/users/$USER" -type l -exec rm "{}" \;
    # Remove packager personal information. We will expand user name when deploy.
    sed -i "s#$USER#@current_user@#" $stgdir/*.reg
    mv "$stgdir/drive_c/users/$USER" "$stgdir/drive_c/users/@current_user@"
    # Merge additional files for this package.
    if [ -d "$specified_dir/bottle" ]; then
        cp -ruv $specified_dir/bottle/* $stgdir
    else
        cp -ruv $curdir/specified/temp/bottle/* $stgdir
    fi

    try_cmd_exit 7z a -snl -t7z "$outfiles/files.7z" "$stgdir/*"
fi

if [ -n "$BOTTLE_CHECKSUM" ];then
    echo "$BOTTLE_CHECKSUM" > "$outfiles/files.md5sum"
else
    md5sum "$outfiles/files.7z" | awk '{print $1}' > "$outfiles/files.md5sum"
fi

echo "<=====package bottle done."

if [ -n "$enable_package_all" ]&&[ $enable_package_all -eq 1 ] ;then
    $curdir/script-packager-per-arch.sh "$SPECIFY_SHELL_PATH_all" "$package_depends_all" "$apprun_cmd_all" "all"
    echo "<=====create all package done."
    exit
fi

if [ -n "$enable_package_i386" ]&&[ $enable_package_i386 -eq 1 ] ;then
    $curdir/script-packager-per-arch.sh "$SPECIFY_SHELL_PATH_i386" "$package_depends_i386" "$apprun_cmd_i386" "i386"
    echo "<=====create x86 package done."
fi

if [ -n "$enable_package_amd64" ]&&[ $enable_package_amd64 -eq 1 ] ;then
    $curdir/script-packager-per-arch.sh "$SPECIFY_SHELL_PATH_amd64" "$package_depends_amd64" "$apprun_cmd_amd64" "amd64"
    echo "<=====create x86 package done."
fi

if [ -n "$enable_package_arm64" ]&&[ $enable_package_arm64 -eq 1 ] ;then
    $curdir/script-packager-per-arch.sh "$SPECIFY_SHELL_PATH_ARM64" "$package_depends_arm64" "$apprun_cmd_arm64" "arm64"
    echo "<=====create arm64 package done."
fi

if [ -n "$enable_package_loongarch64" ]&&[ $enable_package_loongarch64 -eq 1 ] ;then
    $curdir/script-packager-per-arch.sh "$SPECIFY_SHELL_PATH_loongarch64" "$package_depends_loongarch64" "$apprun_cmd_loongarch64" "loongarch64"
    echo "<=====create loongarch64 package done."
fi

exit 0
