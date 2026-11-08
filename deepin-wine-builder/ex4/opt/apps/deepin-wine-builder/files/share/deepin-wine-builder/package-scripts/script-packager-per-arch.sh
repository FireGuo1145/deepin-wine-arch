#!/bin/bash

base_dir=$(dirname $0)
base_dir=$(realpath $base_dir)
run_sh_dir=""
start_shell="$1"
package_depends="$2"
apprun_cmd="$3"
wine_name=${apprun_cmd%%/bin*}
wine_name=${wine_name##*/}
export DEB_HOST_ARCH="$4"

save_build_log()
{
    if [ -f "$build_log" ];then
        echo "$@" >> "$build_log"
    else
        echo "$@"
    fi
}

try_cmd_exit()
{
    "$@"
    if [ $? != 0 ];then
        save_build_log "$@ failed"
        exit 1
    fi
}

RepalceVal()
{
    VALUE="$3"
    VALUE=$(echo ${VALUE//\\/\/})
    find "$1" -type f -exec sed -i "s#$2#$VALUE#" {} \;
}

TranslateTemplateFileUos()
{
    RepalceVal "$1" "@app_description@" "$app_description"
    RepalceVal "$1" "@app_name@" "$app_name"
    RepalceVal "$1" "@app_name_zh_cn@" "$app_name_zh_cn"
    RepalceVal "$1" "@deb_date@" "$deb_date"
    RepalceVal "$1" "@deb_packager@" "$deb_packager"
    RepalceVal "$1" "@deb_version_string@" "$deb_version_string"
    RepalceVal "$1" "@desktop_file_categories@" "$desktop_file_categories"
    RepalceVal "$1" "@desktop_file_main_exe@" "$desktop_file_main_exe"
    RepalceVal "$1" "@wm_class_name@" "$wm_class_name"
    RepalceVal "$1" "@public_bottle_name@" "$public_bottle_name"
    RepalceVal "$1" "@old_package@" "$old_package_name"
    RepalceVal "$1" "@package_depends@" "$package_depends"
    RepalceVal "$1" "@host_arch@" "$DEB_HOST_ARCH"
    RepalceVal "$1" "@mime_type@" "$mime_type"
    RepalceVal "$1" "@mime_exec@" "$mime_exec"
    RepalceVal "$1" "@activex_name@" "$activex_name"
    RepalceVal "$1" "@make_autostart@" "$make_autostart"
    RepalceVal "$1" "@send_to_desktop@" "$send_to_desktop"
    RepalceVal "$1" "@exec_path@" "$EXEC_PATH"
    RepalceVal "$1" "@install_setup@" "$install_setup"
    RepalceVal "$1" "@DISABLE_ATTACH_FILE_DIALOG@" "$DISABLE_ATTACH_FILE_DIALOG"
    RepalceVal "$1" "@DISABLE_FILEDLG_PLUGIN@" "$DISABLE_FILEDLG_PLUGIN"
    RepalceVal "$1" "@EXPORT_ENVS@" "$EXPORT_ENVS"
    RepalceVal "$1" "@deb_package_name@" "$deb_package_name"
    RepalceVal "$1" "@desktop_file_icon@" "$deb_package_name"
    RepalceVal "$1" "@run_sh_dir@" "$run_sh_dir"
    RepalceVal "$1" "@start_shell_path@" "$start_shell"
    RepalceVal "$1" "@apprun_cmd@" "$apprun_cmd"
    RepalceVal "$1" "@patch_loader@" "$patch_loader"
    RepalceVal "$1" "@version_info@" "$version_info"
    RepalceVal "$1" "@patch_version@" "$hack_patch_version"
    RepalceVal "$1" "@deb_install_size@" "$install_size"
    RepalceVal "$1" "@deb_download_size@" "$download_size"
    RepalceVal "$1" "@BOX86_CMD@" "$box86_cmd"
    RepalceVal "$1" "@disable_clean_bottle@" "$disable_clean_bottle"
    RepalceVal "$1" "@wine_services_no_delay@" "$wine_services_no_delay"
    RepalceVal "$1" "@wine_services_disable@" "$wine_services_disable"
    RepalceVal "$1" "@def_emu_name@" "$default_emu_name"
}

if [ -f "$WINE_DEB_FILE" ];then
    apprun_cmd="/opt/apps/$deb_package_name/files/deepin-wine/deepin-wine-runner"
fi

echo "app run cmd:        $apprun_cmd"
echo "run wine cmd:        $wine_name"
echo "run shell path:      $start_shell"

package_workdir="$HOME/.cache/deepin-wine-builder/"
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
echo "pacage save dir: $uos_package_save"

if [ -n "${deb_file_name}" ]; then
    PKG_FILE="${deb_file_name}_${deb_version_string}_${DEB_HOST_ARCH}.deb"
else
    PKG_FILE="${deb_package_name}_${deb_version_string}_${DEB_HOST_ARCH}.deb"
fi

#默认情况用0.2.6版本的box86
if [ -z "$box86_cmd" ];then
    box86_cmd="/opt/deepin-box86/stable/box86"
fi

echo "=====>Creating additional files..."
cd "$outdir"
if [ -d "$dstdir/debian" ]; then
    rm -rf "$dstdir/debian"
fi
cp -r "$base_dir/debian/" "$dstdir"
TranslateTemplateFileUos "$dstdir/debian/"

#高版本debhelper中dh_install需要指定目录，所以增加$deb_package_name.install文件至/debian目录下
dst_install_file="$dstdir/debian/$deb_package_name.install"
cp "$base_dir/template/target.install" $dst_install_file
filelist=`ls $dstdir`
for file in $filelist
do
    if [ $file == "debian" ]; then
        continue
    fi
    file="/"$file"/*"
    test -s $dst_install_file && sed -i "\$a $file" $dst_install_file || echo "$file" >> $dst_install_file
done

[ -z "$deb_package_specified_path" ] && deb_package_specified_path="$base_dir/specified"

if [ -n "$PROGRAM_INDEX_NAME" ];then
    specified_dir="$deb_package_specified_path/$PROGRAM_INDEX_NAME"
else
    specified_dir="$deb_package_specified_path/$deb_package_name"
fi

if [ -d "$specified_dir/root/" ]; then
    if [ -d "$dstdir/usr/" ]; then
        echo "$dstdir/usr/* /usr" &>> "$dstdir/debian/install"
    fi
    if [ -n "$install_setup" ];then
        md5sum "$outfiles/$install_setup" | awk '{print $1}' > "$outfiles/setup.md5sum"
    fi
fi

if [ "$deb_release_type" == "release_yml_deb" ]; then
    cp "$base_dir/template/run-yml.sh" "$outfiles/run.sh"
    TranslateTemplateFileUos "$outfiles/run.sh"
else
    if [[ -d "$deb_entries_dir" ]]; then
        cp "$deb_entries_dir/"uninstall*.sh "$outfiles"
        chmod +x "$outfiles"/uninstall*.sh

        cp "$deb_entries_dir/"run*.sh "$outfiles"
        chmod +x "$outfiles"/run*.sh
        for s in $(find "$outfiles" -iname "run*.sh" -or -iname "uninstall*.sh"); do
            TranslateTemplateFileUos "$s"
        done
    else
        cp "$base_dir/template/run.sh" "$outfiles"
        TranslateTemplateFileUos "$outfiles/run.sh"
    fi
fi

cp "$base_dir/template/info" "$outdir"
TranslateTemplateFileUos "$outdir/info"

#if we have perpare a entries dir, use it
if [[ -d "$deb_entries_dir" ]]; then
    cp -r "$deb_entries_dir"/applications $outentries
    TranslateTemplateFileUos "$outentries"/applications
#if no desktop_file_categories, don't create desktop
elif [ -n "$desktop_file_categories" ]; then
    mkdir -p "$outentries/applications"
    cp "$base_dir/template/target.desktop" "$outentries/applications/$deb_package_name.desktop"
    TranslateTemplateFileUos "$outentries/applications/$deb_package_name.desktop"

    # TODO: We should generate icons from main program automatically.
    cd "$package_workdir/icons"
    find -iname "$desktop_file_icon" -exec dirname "{}" \; | xargs -I "{}" mkdir -p "$outentries/icons/{}"
    find -iname "$desktop_file_icon" -exec cp "{}" "$outentries/icons/{}" \;

fi

extract_predlls()
{
   if [ $DEB_HOST_ARCH = "arm64" ];then
       patch_file="$PREDLL_PATCH_arm64"
       patch_id="$PREDLL_ID_arm64"
   elif [ $DEB_HOST_ARCH = "i386" ];then
       patch_file="$PREDLL_PATCH_i386"
       patch_id="$PREDLL_ID_i386"
   elif [ $DEB_HOST_ARCH = "loongarch64" ];then
       patch_file="$PREDLL_PATCH_loongarch64"
       patch_id="$PREDLL_ID_loongarch64"
   fi
   # 其他架构没有指定的情况使用x86架构的替换库
   if [ -z "$patch_file" ];then
       patch_file="$PREDLL_PATCH_i386"
   fi
   if [ -z "$patch_id" ];then
       patch_id="$PREDLL_ID_i386"
   fi
   
   id_file="$outfiles/.id"
   if [ -n "$APP_CONFIG_ID" ];then
       echo $APP_CONFIG_ID > "$id_file"
   fi

   predll_dir_extracted="$package_workdir/$patch_id"

   if [ -f "$patch_file" ];then
       if [ -d "$predll_dir_extracted" ];then
           rm -rf "$predll_dir_extracted"
       fi
   
       mkdir "$predll_dir_extracted"
       try_cmd_exit tar -xf "$patch_file" -C "$predll_dir_extracted"
   
       dlls_patch="$predll_dir_extracted"

       if [ -f "$dlls_patch/amd64/dlls/deepin-wine8" ];then
           dlls_patch="$dlls_patch/amd64/dlls"
           mkdir "$dlls_patch/x86_64-unix"
           mv "$dlls_patch/"*.so "$dlls_patch/x86_64-unix"
       elif [ -f "$dlls_patch/i386/dlls/deepin-wine8" ];then
           dlls_patch="$dlls_patch/i386/dlls"
           mkdir "$dlls_patch/i386-unix"
           mv "$dlls_patch/"*.so "$dlls_patch/i386-unix"
       elif [ "$WIN_ARCH" = "win64" ];then
           dlls_patch="$dlls_patch/amd64/dlls"
       else
           dlls_patch="$dlls_patch/i386/dlls"
       fi
   
       if [ -n "$APP_CONFIG_ID" ];then
           echo "$patch_id" >> "$id_file"
       fi
       if [ -f "${dlls_patch}/fixer-commit-id" ];then
           rm "${dlls_patch}/fixer-commit-id"
       fi

       if [ -f "$dlls_patch/wineserver" ];then
           if [ $DEB_HOST_ARCH = "arm64" ];then
               # arm 下面需要同时打包32位和64位的wineserver
               if [ "$WIN_ARCH" = "win64" ]; then
                   mv "$dlls_patch/wineserver" "$dlls_patch/wineserver64"
                   mv "$predll_dir_extracted/i386/dlls/wineserver" "$dlls_patch/wineserver"
               else
                   mv "$predll_dir_extracted/amd64/dlls/wineserver" "$dlls_patch/wineserver64"
               fi
           else
               # 其他架构只用打包64位的wineserver
               if [ "$WIN_ARCH" = "win32" ]; then
                   mv "$predll_dir_extracted/amd64/dlls/wineserver" "$dlls_patch/wineserver"
               fi
           fi
       fi

       find "$dlls_patch" -maxdepth 1 -type f  | xargs -i strip {}
       find "$dlls_patch/"*-unix -maxdepth 1 -type f  | xargs -i strip {}
   fi
}

install_predlls()
{
    if [ -d "$wine_install_dir" ];then
        echo "copy predlls to wine install dir: $wine_install_dir"
        dist_dlls="$wine_install_dir/lib/wine"
        #32位wineserver在没有32位libc6的情况需要用脚本启动
        if [ -f "$dlls_path/wineserver" ];then
            save_build_log "copy predll wineserver"
            if [[ $DEB_HOST_ARCH != "arm64" ]] && [[ "$predll_dir_extracted/amd64/dlls" == "$dlls_path" ]];then
                # 32位wineserver并且不是打包arm版本的情况需要通过脚本运行wineserver
                mv "$dlls_path/wineserver" "$wine_install_dir/bin/wineserver.real"
                cp "$base_dir/template/wineserver" "$wine_install_dir/bin/wineserver"
            else
                mv "$dlls_path/wineserver" "$wine_install_dir/bin/wineserver"
            fi
        fi
    else
        dist_dlls="${outfiles}/dlls"
        if [[ "$WIN_ARCH" == "win64" ]] && [[ ! -f "$dlls_patch/deepin-wine8" ]]; then
            dist_dlls="${outfiles}/dlls/64"
        fi
        if [ -d "$dist_dlls" ];then
            rm -rf "$dist_dlls"
        fi
        mkdir -p "$dist_dlls"
    fi

    rm "$dlls_patch/deepin-wine8"
    cd "$dlls_patch"
    all_predlls=$(find . -type f)
    cd -
    save_build_log "copy predlls:"
    save_build_log "$all_predlls"
    try_cmd_exit cp -r "$dlls_patch"/* "$dist_dlls"

    if [ -f "${outfiles}/pre_run.sh" ];then
        if cat "${outfiles}/pre_run.sh" | grep WINEPREDLL;then
            save_build_log "不支持重新指定WINEPREDLL环境变量，WINEPREDLL固定在dlls目录"
            exit 1
        fi
    fi
}

extract_wine_deb()
{
    local extracted_wine_deb="$package_workdir/deepin-wine-deb"
    if [ -f "$WINE_DEB_FILE" ];then
        if [ -d "$extracted_wine_deb" ];then
            rm -rf "$extracted_wine_deb"
        fi
        dpkg -x "$WINE_DEB_FILE" "$extracted_wine_deb"
        wine_cmd_path=$(find "$extracted_wine_deb" -type f -name wine)
        wine_install_dir=$(dirname $wine_cmd_path)
        wine_install_dir=$(realpath "$wine_install_dir/../")
        if [ -d "$outfiles/deepin-wine" ];then
            rm -rf "$outfiles/deepin-wine"
        fi
        mv "$wine_install_dir" "$outfiles/deepin-wine"
        wine_install_dir="$outfiles/deepin-wine"

        if [ $DEB_HOST_ARCH = "arm64" ];then
            mv "$wine_install_dir/bin/wineserver-i386" "$wine_install_dir/bin/wineserver"
            cp "$base_dir/deepin-wine-runners/wine-arm" "$outfiles/deepin-wine/deepin-wine-runner"
        else
            cp "$base_dir/deepin-wine-runners/wine-i386" "$outfiles/deepin-wine/deepin-wine-runner"
        fi
        chmod +x "$outfiles/deepin-wine/deepin-wine-runner"
    fi
}

if [ -f "$WINE_DEB_FILE" ];then
    extract_wine_deb
fi
extract_predlls
if [ -n "$dlls_patch" ];then
    install_predlls
fi

cd "$dstdir"
echo "$outdir/* /opt/apps/$deb_package_name" &>> "debian/install"
echo "<=====done."

echo "=====>Creating deb package..."
fakeroot "debian/build" "$dstdir" "$PKG_FILE"
echo "<=====done."

echo "=====> Removing temporary files..."
mv "$dstdir/$PKG_FILE" "$uos_package_save"
if [ -n "$APP_CONFIG_ID" ];then
    deb_md5=$(md5sum "$uos_package_save/$PKG_FILE" | awk '{print $1}')
    package_id=$(cat "$id_file" | xargs printf '%s ')
    echo "$PKG_FILE md5: $deb_md5 fixer commit: $package_id" >> "${uos_package_save}/${deb_package_name}-info"
fi
echo -e "\n\nDeb file generated:"
realpath "$uos_package_save/$PKG_FILE"
