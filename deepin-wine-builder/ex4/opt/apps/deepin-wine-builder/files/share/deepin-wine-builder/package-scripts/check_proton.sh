#!/usr/bin/env bash

# Find the ge_proton install directory
# GE_PROTON_DIR_OVERRIDE can be set for testing purposes
ge_proton_install_dir=""
if [ -n "$GE_PROTON_DIR_OVERRIDE" ]; then
    ge_proton_install_dir="$GE_PROTON_DIR_OVERRIDE"
else
    for dir in /opt/deepin-ge-proton*; do
        if [ -d "$dir" ]; then
            ge_proton_install_dir="$dir"
            break
        fi
    done
fi

# Check if the current distro is UOS V20
check_uos_v20() {
    if [ "$UOS_V20" = "1" ]; then
        return 0
    elif [ "$UOS_V20" = "0" ]; then
        return 1
    else
        local distro_name=""
        local distro_version=""
        if [ -f /etc/os-release ]; then
            while IFS='=' read -r key value; do
                # Remove surrounding quotes from value
                value="${value%\"}"
                value="${value#\"}"
                case "$key" in
                    NAME)
                        distro_name="$value"
                        ;;
                    VERSION)
                        distro_version="$value"
                        ;;
                esac
            done < /etc/os-release
        fi
        if [ "$distro_name" = "uos" ] && [ "$distro_version" = "20" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Define paths
current_dir="$ge_proton_install_dir"
chksum_type="sha1sum"

runtime_path="${current_dir}/runtime"
runtime_steam_tarball_file="SteamLinuxRuntime_sniper.tar.xz"
runtime_steam_tarball_path="${runtime_path}/${runtime_steam_tarball_file}"
runtime_steam_tarball_chksum_now="${runtime_path}/${runtime_steam_tarball_file}.${chksum_type}"

runtime_python_embed_v20_tarball_file="python_embed_v20.tar.xz"
runtime_python_embed_v20_tarball_path="${runtime_path}/${runtime_python_embed_v20_tarball_file}"
runtime_python_embed_v20_tarball_chksum_now="${runtime_path}/${runtime_python_embed_v20_tarball_file}.${chksum_type}"

local_path="${HOME}/.local/share/umu-helper"
runtime_steam_path="${local_path}/SteamLinuxRuntime_sniper"
runtime_python_embed_v20_path="${local_path}/python_embed_v20"

runtime_steam_tarball_chksum_local="${local_path}/${runtime_steam_tarball_file}.${chksum_type}"
runtime_python_embed_v20_tarball_chksum_local="${local_path}/${runtime_python_embed_v20_tarball_file}.${chksum_type}"

runtime_umu_path="${local_path}/umu"
runtime_umu_file="${runtime_umu_path}/umu"
runtime_steam_entry_point_file="${runtime_umu_path}/_v2-entry-point"
runtime_umu_shim_script_file="${runtime_umu_path}/umu-shim"

runtime_steam_run_file="${runtime_umu_path}/run"
runtime_steam_run_bak_file="${runtime_umu_path}/run.bak"
runtime_steam_run_service_file="${runtime_umu_path}/run-service"

current_runtime_steam_run_file="${runtime_path}/run"
current_runtime_steam_run_service_file="${runtime_path}/run-service"

# Compare md5 of two files, return 0 if same, 1 if different or error
is_same_file() {
    local path1="$1"
    local path2="$2"
    if [ ! -f "$path1" ] || [ ! -f "$path2" ]; then
        return 1
    fi
    local md51 md52
    md51=$(md5sum "$path1" 2>/dev/null | awk '{print $1}')
    md52=$(md5sum "$path2" 2>/dev/null | awk '{print $1}')
    if [ -z "$md51" ] || [ -z "$md52" ]; then
        return 1
    fi
    if [ "$md51" != "$md52" ]; then
        echo "Checksum of run script is not equal" >&2
        echo "${path1}: ${md51}" >&2
        echo "${path2}: ${md52}" >&2
        return 1
    fi
    return 0
}

# Check whether components need to be installed
# Returns 0 (true) if any component needs install, 1 (false) otherwise
check_components_need_install() {
    local need_install_steam_runtime=false
    local need_install_python_runtime=false
    local need_install_steam_runtime_script=false

    echo "Checking ${runtime_umu_path}."

    # Check steam runtime
    if [ ! -e "${runtime_umu_path}" ]; then
        need_install_steam_runtime=true
        echo "The directory of umu is not exists: ${runtime_umu_path}."
    elif [ ! -e "${runtime_steam_tarball_chksum_local}" ]; then
        need_install_steam_runtime=true
        echo "The chksum of umu is not exists: ${runtime_steam_tarball_chksum_local}."
    else
        chksum_local=$(head -1 "${runtime_steam_tarball_chksum_local}" 2>/dev/null)
        chksum_now=$(head -1 "${runtime_steam_tarball_chksum_now}" 2>/dev/null)
        if [ -z "$chksum_local" ] || [ -z "$chksum_now" ]; then
            need_install_steam_runtime=true
        else
            echo "The chksum of local file is ${chksum_local}."
            echo "The chksum of new file is ${chksum_now}."
            if [ "$chksum_local" != "$chksum_now" ]; then
                echo "The two chksum is not equal."
                need_install_steam_runtime=true
            else
                echo "The two chksum is equal."
            fi
        fi
    fi

    # Check python_embed_v20 runtime (only on UOS V20)
    if check_uos_v20; then
        echo "The distro is UOS V20."
        if [ ! -e "${runtime_python_embed_v20_path}" ]; then
            need_install_python_runtime=true
            echo "The directory of python_embed_v20 is not exists: ${runtime_python_embed_v20_path}."
        elif [ ! -e "${runtime_python_embed_v20_tarball_chksum_local}" ]; then
            need_install_python_runtime=true
            echo "The chksum of python_embed_v20 is not exists: ${runtime_python_embed_v20_tarball_chksum_local}."
        else
            chksum_local=$(head -1 "${runtime_python_embed_v20_tarball_chksum_local}" 2>/dev/null)
            chksum_now=$(head -1 "${runtime_python_embed_v20_tarball_chksum_now}" 2>/dev/null)
            if [ -z "$chksum_local" ] || [ -z "$chksum_now" ]; then
                need_install_python_runtime=true
            else
                echo "The chksum of local file is ${chksum_local}."
                echo "The chksum of new file is ${chksum_now}."
                if [ "$chksum_local" != "$chksum_now" ]; then
                    echo "The two chksum is not equal."
                    need_install_python_runtime=true
                else
                    echo "The two chksum is equal."
                fi
            fi
        fi
    fi

    # Check md5 hash of scripts to launch steam runtime
    if ! is_same_file "${current_runtime_steam_run_file}" "${runtime_steam_run_file}"; then
        need_install_steam_runtime_script=true
    fi
    if ! is_same_file "${current_runtime_steam_run_service_file}" "${runtime_steam_run_service_file}"; then
        need_install_steam_runtime_script=true
    fi

    if $need_install_steam_runtime || $need_install_python_runtime || $need_install_steam_runtime_script; then
        return 0
    else
        return 1
    fi
}

# Main
if [ -z "$ge_proton_install_dir" ] || [ ! -e "$ge_proton_install_dir" ]; then
    # 没有安装 deb 包，直接退出
    exit 0
fi

if check_components_need_install; then
    exit 1
else
    exit 0
fi
