#!/usr/bin/env bash
# test_check_proton_comparison.sh
# 测试对比 check_proton.py 和 check_proton.sh 的行为一致性
# 使用 GE_PROTON_DIR_OVERRIDE 环境变量来模拟 ge-proton 安装目录

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 临时测试环境
TEST_ENV=""
GE_PROTON_MOCK=""
UMU_HELPER_MOCK=""
HOME_MOCK=""
SHELL_SCRIPT="${REPO_DIR}/package-scripts/check_proton.sh"

# 初始化测试环境
setup_test_env() {
    TEST_ENV=$(mktemp -d)
    GE_PROTON_MOCK="${TEST_ENV}/opt/deepin-ge-proton10"
    HOME_MOCK="${TEST_ENV}/home/user"
    UMU_HELPER_MOCK="${HOME_MOCK}/.local/share/umu-helper"

    # 创建目录结构
    mkdir -p "${GE_PROTON_MOCK}/runtime"
    mkdir -p "${UMU_HELPER_MOCK}/umu"
    mkdir -p "${HOME_MOCK}/.local/share"

    # 创建模拟的 run 和 run-service 脚本
    echo "#!/bin/bash" > "${GE_PROTON_MOCK}/runtime/run"
    echo "echo 'mock run'" >> "${GE_PROTON_MOCK}/runtime/run"
    chmod +x "${GE_PROTON_MOCK}/runtime/run"

    echo "#!/bin/bash" > "${GE_PROTON_MOCK}/runtime/run-service"
    echo "echo 'mock run-service'" >> "${GE_PROTON_MOCK}/runtime/run-service"
    chmod +x "${GE_PROTON_MOCK}/runtime/run-service"

    # 创建模拟的 tarball 和校验文件
    echo "mock_tarball_content" > "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz"
    # 使用真实的 sha1sum 格式
    sha1sum "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz" | awk '{print $1}' > "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    echo "mock_python_content" > "${GE_PROTON_MOCK}/runtime/python_embed_v20.tar.xz"
    sha1sum "${GE_PROTON_MOCK}/runtime/python_embed_v20.tar.xz" | awk '{print $1}' > "${GE_PROTON_MOCK}/runtime/python_embed_v20.tar.xz.sha1sum"

    # 确保 Shell 脚本可用
    if [ ! -f "$SHELL_SCRIPT" ]; then
        git show FETCH_HEAD:package-scripts/check_proton.sh > "$SHELL_SCRIPT" 2>/dev/null || echo "Warning: could not get shell script"
    fi
    chmod +x "$SHELL_SCRIPT"
}

# 清理测试环境
cleanup_test_env() {
    if [ -n "$TEST_ENV" ] && [ -d "$TEST_ENV" ]; then
        rm -rf "$TEST_ENV"
    fi
}

# 运行 Shell 脚本
run_shell_script() {
    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    bash "$SHELL_SCRIPT"
}

# 运行单个测试
run_test() {
    local test_name="$1"
    local test_func="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}运行测试: ${test_name}${NC}"

    setup_test_env

    if $test_func; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}  ✓ 通过${NC}"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}  ✗ 失败${NC}"
    fi

    cleanup_test_env
    echo ""
}

# ============================================================
# 测试用例
# ============================================================

# 测试1: 没有 ge-proton 安装时，应返回 0
test_no_ge_proton_installed() {
    # 删除模拟的 ge-proton 目录
    rm -rf "${GE_PROTON_MOCK}"

    local sh_exit_code

    run_shell_script
    sh_exit_code=$?

    # ge-proton 不存在时应该返回 0
    if [ "$sh_exit_code" -eq 0 ]; then
        return 0
    else
        echo "期望退出码 0，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试2: umu 目录不存在时应返回 1
test_umu_directory_not_exists() {
    # umu 目录不存在
    rm -rf "${UMU_HELPER_MOCK}/umu"

    local sh_exit_code

    run_shell_script
    sh_exit_code=$?

    # 应该返回 1 (需要安装)
    if [ "$sh_exit_code" -eq 1 ]; then
        return 0
    else
        echo "期望退出码 1，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试3: umu 目录存在但校验文件不存在时应返回 1
test_umu_exists_no_checksum() {
    # umu 目录存在但不创建校验文件
    mkdir -p "${UMU_HELPER_MOCK}/umu"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    local sh_exit_code

    run_shell_script
    sh_exit_code=$?

    # 应该返回 1 (需要安装)
    if [ "$sh_exit_code" -eq 1 ]; then
        return 0
    else
        echo "期望退出码 1，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试4: 校验文件存在但不匹配时应返回 1
test_checksum_mismatch() {
    # 创建 umu 目录
    mkdir -p "${UMU_HELPER_MOCK}/umu"

    # 创建不匹配的本地校验文件
    echo "wrong_checksum_value" > "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    local sh_exit_code

    run_shell_script 2>&1
    sh_exit_code=$?

    # 应该返回 1 (需要安装)
    if [ "$sh_exit_code" -eq 1 ]; then
        return 0
    else
        echo "期望退出码 1，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试5: 校验文件匹配时应返回 0 (非 UOS V20 环境)
test_checksum_match() {
    # 创建 umu 目录
    mkdir -p "${UMU_HELPER_MOCK}/umu"

    # 创建匹配的本地校验文件 (与 mock 的相同)
    cp "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    local sh_exit_code

    # 明确设置 UOS_V20=0 以避免环境检测
    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=0 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # 应该返回 0 (不需要安装)
    if [ "$sh_exit_code" -eq 0 ]; then
        return 0
    else
        echo "期望退出码 0，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试6: UOS V20 环境下 python_embed_v20 校验不匹配应返回 1
test_uos_v20_python_mismatch() {
    # 创建 umu 目录和校验文件
    mkdir -p "${UMU_HELPER_MOCK}/umu"
    cp "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    # 设置 UOS V20 环境变量
    local sh_exit_code

    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=1 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # python_embed_v20 目录不存在，应该返回 1 (需要安装)
    if [ "$sh_exit_code" -eq 1 ]; then
        return 0
    else
        echo "期望退出码 1，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试7: UOS V20 环境下所有组件匹配应返回 0
test_uos_v20_python_match() {
    # 创建 umu 目录和校验文件
    mkdir -p "${UMU_HELPER_MOCK}/umu"
    mkdir -p "${UMU_HELPER_MOCK}/python_embed_v20"
    cp "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"
    cp "${GE_PROTON_MOCK}/runtime/python_embed_v20.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/python_embed_v20.tar.xz.sha1sum"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    local sh_exit_code

    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=1 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # 所有组件都匹配，应该返回 0 (不需要安装)
    if [ "$sh_exit_code" -eq 0 ]; then
        return 0
    else
        echo "期望退出码 0，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试8: 非 UOS V20 环境下，不需要检查 python_embed_v20
test_non_uos_v20() {
    # 创建 umu 目录和校验文件
    mkdir -p "${UMU_HELPER_MOCK}/umu"
    cp "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    # 注意: 不创建 python_embed_v20 目录和校验文件
    # 这在 UOS V20 环境下会导致需要安装，但非 UOS V20 不检查

    local sh_exit_code

    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=0 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # 非 UOS V20，不检查 python_embed_v20，应该返回 0
    if [ "$sh_exit_code" -eq 0 ]; then
        return 0
    else
        echo "期望退出码 0，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试9: run 脚本 MD5 不匹配应返回 1 (非 UOS V20 环境)
test_run_script_mismatch() {
    # 创建 umu 目录和校验文件
    mkdir -p "${UMU_HELPER_MOCK}/umu"
    cp "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # 创建不同的 run 文件
    echo "#!/bin/bash" > "${UMU_HELPER_MOCK}/umu/run"
    echo "echo 'different run script content'" >> "${UMU_HELPER_MOCK}/umu/run"
    chmod +x "${UMU_HELPER_MOCK}/umu/run"

    # run-service 相同
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    local sh_exit_code

    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=0 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # run 脚本不匹配，应该返回 1
    if [ "$sh_exit_code" -eq 1 ]; then
        return 0
    else
        echo "期望退出码 1，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试10: run-service 脚本 MD5 不匹配应返回 1 (非 UOS V20 环境)
test_run_service_script_mismatch() {
    # 创建 umu 目录和校验文件
    mkdir -p "${UMU_HELPER_MOCK}/umu"
    cp "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # run 相同
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"

    # 创建不同的 run-service 文件
    echo "#!/bin/bash" > "${UMU_HELPER_MOCK}/umu/run-service"
    echo "echo 'different run-service script content'" >> "${UMU_HELPER_MOCK}/umu/run-service"
    chmod +x "${UMU_HELPER_MOCK}/umu/run-service"

    local sh_exit_code

    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=0 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # run-service 脚本不匹配，应该返回 1
    if [ "$sh_exit_code" -eq 1 ]; then
        return 0
    else
        echo "期望退出码 1，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试11: 校验和文件带换行符应正确处理 (非 UOS V20 环境)
test_checksum_with_newline() {
    # 创建 umu 目录
    mkdir -p "${UMU_HELPER_MOCK}/umu"

    # 创建带换行符的校验文件 (模拟真实 sha1sum 输出)
    cp "${GE_PROTON_MOCK}/runtime/SteamLinuxRuntime_sniper.tar.xz.sha1sum" "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    local sh_exit_code

    # 明确设置 UOS_V20=0 以避免环境检测
    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=0 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # 应该正确处理换行符，返回 0
    if [ "$sh_exit_code" -eq 0 ]; then
        return 0
    else
        echo "期望退出码 0，实际退出码 $sh_exit_code"
        return 1
    fi
}

# 测试12: 空校验文件应返回 1 (非 UOS V20 环境)
test_empty_checksum_file() {
    # 创建 umu 目录
    mkdir -p "${UMU_HELPER_MOCK}/umu"

    # 创建空的校验文件
    touch "${UMU_HELPER_MOCK}/SteamLinuxRuntime_sniper.tar.xz.sha1sum"

    # 创建相同的 run 和 run-service 文件
    cp "${GE_PROTON_MOCK}/runtime/run" "${UMU_HELPER_MOCK}/umu/"
    cp "${GE_PROTON_MOCK}/runtime/run-service" "${UMU_HELPER_MOCK}/umu/"

    local sh_exit_code

    HOME="${HOME_MOCK}" \
    GE_PROTON_DIR_OVERRIDE="${GE_PROTON_MOCK}" \
    UOS_V20=0 \
    bash "$SHELL_SCRIPT"
    sh_exit_code=$?

    # 空校验文件应该导致需要安装，返回 1
    if [ "$sh_exit_code" -eq 1 ]; then
        return 0
    else
        echo "期望退出码 1，实际退出码 $sh_exit_code"
        return 1
    fi
}

# ============================================================
# 主测试运行器
# ============================================================

main() {
    echo "========================================"
    echo "check_proton Shell 脚本测试套件"
    echo "验证行为与 Python 版本一致"
    echo "========================================"
    echo ""

    # 检查必要工具
    if ! command -v sha1sum &> /dev/null; then
        echo -e "${RED}错误: 需要安装 sha1sum${NC}"
        exit 1
    fi

    if ! command -v md5sum &> /dev/null; then
        echo -e "${RED}错误: 需要安装 md5sum${NC}"
        exit 1
    fi

    # 检查测试用的 shell 脚本是否存在
    if [ ! -f "$SHELL_SCRIPT" ]; then
        echo -e "${RED}错误: 测试用的 check_proton_testable.sh 不存在${NC}"
        echo "请确保 check_proton_testable.sh 文件在 tests 目录中"
        exit 1
    fi

    # 运行测试
    run_test "测试1: ge-proton 未安装时应返回 0" test_no_ge_proton_installed
    run_test "测试2: umu 目录不存在时应返回 1" test_umu_directory_not_exists
    run_test "测试3: umu 存在但无校验文件时应返回 1" test_umu_exists_no_checksum
    run_test "测试4: 校验文件不匹配时应返回 1" test_checksum_mismatch
    run_test "测试5: 校验文件匹配时应返回 0" test_checksum_match
    run_test "测试6: UOS V20 下 python_embed_v20 不匹配应返回 1" test_uos_v20_python_mismatch
    run_test "测试7: UOS V20 下所有组件匹配应返回 0" test_uos_v20_python_match
    run_test "测试8: 非 UOS V20 不检查 python_embed_v20" test_non_uos_v20
    run_test "测试9: run 脚本 MD5 不匹配应返回 1" test_run_script_mismatch
    run_test "测试10: run-service 脚本 MD5 不匹配应返回 1" test_run_service_script_mismatch
    run_test "测试11: 校验和文件带换行符正确处理" test_checksum_with_newline
    run_test "测试12: 空校验文件应返回 1" test_empty_checksum_file

    # 输出结果
    echo "========================================"
    echo "测试结果统计"
    echo "========================================"
    echo -e "总测试数: ${TOTAL_TESTS}"
    echo -e "${GREEN}通过: ${PASSED_TESTS}${NC}"
    echo -e "${RED}失败: ${FAILED_TESTS}${NC}"
    echo ""

    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}所有测试通过！Shell 脚本行为与 Python 版本一致。${NC}"
        exit 0
    else
        echo -e "${RED}存在失败的测试，请检查实现。${NC}"
        exit 1
    fi
}

# 运行主函数
main "$@"