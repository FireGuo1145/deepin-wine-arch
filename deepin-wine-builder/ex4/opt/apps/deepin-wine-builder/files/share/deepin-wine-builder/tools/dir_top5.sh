#!/bin/bash
# 目录大小排行分析工具
# 输出指定目录下子文件夹/文件大小排行前5的信息

set -e

# 默认参数
DEFAULT_DEPTH=5
TOP_N=5

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 使用说明
usage() {
    echo "用法: $0 <目录> [深度]"
    echo ""
    echo "参数:"
    echo "  目录    要分析的目标目录"
    echo "  深度    子目录遍历深度 (默认: $DEFAULT_DEPTH)"
    echo ""
    echo "示例:"
    echo "  $0 /home/user"
    echo "  $0 /home/user 3"
    exit 1
}

# 检查参数
if [ "$1" = "-h"  ]; then
    usage
fi

TARGET_DIR="$HOME"
if [ -d "$1" ];then
    TARGET_DIR="$1"
fi
DEPTH="${2:-$DEFAULT_DEPTH}"

# 验证目录
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}错误: 目录不存在: $TARGET_DIR${NC}"
    exit 1
fi

# 将人类可读大小转换为字节数
human_to_bytes() {
    local size=$1
    local num=$(echo "$size" | sed 's/[^0-9.]//g')
    local unit=$(echo "$size" | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')

    case "$unit" in
        T|TB) echo $(awk "BEGIN {printf \"%.0f\", $num * 1024 * 1024 * 1024 * 1024}") ;;
        G|GB) echo $(awk "BEGIN {printf \"%.0f\", $num * 1024 * 1024 * 1024}") ;;
        M|MB) echo $(awk "BEGIN {printf \"%.0f\", $num * 1024 * 1024}") ;;
        K|KB) echo $(awk "BEGIN {printf \"%.0f\", $num * 1024}") ;;
        *) echo $(awk "BEGIN {printf \"%.0f\", $num}") ;;
    esac
}

# 获取目录树结构（包含文件和目录）
get_tree() {
    local dir=$1
    local prefix=$2
    local current_depth=$3
    local max_depth=$4
    local parent_bytes=$5

    if [ $current_depth -ge $max_depth ]; then
        return
    fi

    # 获取所有子项（文件和目录）
    local entries=()
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        entries+=("$line")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -exec du -sh {} \; 2>/dev/null | sort -hr)

    # 过滤：只保留大于父目录10%的项
    local filtered=()
    for entry in "${entries[@]}"; do
        local size=$(echo "$entry" | awk '{print $1}')
        local entry_bytes=$(human_to_bytes "$size")
        # 过滤条件：大小 >= 父目录的10%
        if [ $entry_bytes -ge $((parent_bytes / 10)) ]; then
            filtered+=("$entry")
        fi
    done

    # 取前5个
    local top_entries=()
    local idx=0
    for entry in "${filtered[@]}"; do
        if [ $idx -ge $TOP_N ]; then
            break
        fi
        top_entries+=("$entry")
        idx=$((idx + 1))
    done

    local count=${#top_entries[@]}
    local i=0

    for entry in "${top_entries[@]}"; do
        local size=$(echo "$entry" | awk '{print $1}')
        local path=$(echo "$entry" | awk '{$1=""; print $0}' | sed 's/^[[:space:]]*//')
        local name=$(basename "$path")

        # 跳过 . 和 ..
        if [ "$name" = "." ] || [ "$name" = ".." ]; then
            continue
        fi

        i=$((i + 1))
        local connector="├──"
        if [ $i -eq $count ]; then
            connector="└──"
        fi

        # 判断是文件还是目录
        local suffix="/"
        if [ -f "$path" ]; then
            suffix=""
        fi

        printf "%s%s %s %s%s\n" "$prefix" "$connector" "$size" "$name" "$suffix"

        # 递归处理子目录
        if [ -d "$path" ]; then
            local new_prefix="${prefix}│   "
            if [ $i -eq $count ]; then
                new_prefix="${prefix}    "
            fi
            local entry_bytes=$(human_to_bytes "$size")
            get_tree "$path" "$new_prefix" $((current_depth + 1)) "$max_depth" "$entry_bytes"
        fi
    done
}

# 主程序
echo -e "${BLUE}=== 目录大小排行 Top $TOP_N ===${NC}"
echo -e "分析目录: ${GREEN}$TARGET_DIR${NC}"
echo -e "遍历深度: ${YELLOW}$DEPTH${NC}"
echo ""

# 获取顶级子项大小并排序（包含文件和目录）
sorted_items=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    size=$(echo "$line" | awk '{print $1}')
    path=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^[[:space:]]*//')
    name=$(basename "$path")
    # 跳过 . 和 ..
    if [ "$name" != "." ] && [ "$name" != ".." ] && [ -n "$name" ]; then
        sorted_items+=("$size|$name|$path")
    fi
done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -exec du -sh {} \; 2>/dev/null | sort -hr)

# 输出前N个项
count=0
for item in "${sorted_items[@]}"; do
    if [ $count -ge $TOP_N ]; then
        break
    fi

    size="${item%%|*}"
    rest="${item#*|}"
    name="${rest%%|*}"
    path="${rest#*|}"

    count=$((count + 1))

    # 判断是文件还是目录
    if [ -f "$path" ]; then
        echo -e "${YELLOW}$count.${NC} ${GREEN}$name${NC}  ${size}"
    else
        echo -e "${YELLOW}$count.${NC} ${GREEN}$name/${NC}  ${size}"
    fi

    # 显示树形结构（仅目录）
    if [ -d "$path" ]; then
        item_bytes=$(human_to_bytes "$size")
        get_tree "$path" "" 1 "$DEPTH" "$item_bytes"
    fi
    echo ""
done

# 统计信息
total_size=$(du -sh "$TARGET_DIR" 2>/dev/null | awk '{print $1}')
subdir_count=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
file_count=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l)

echo -e "${BLUE}=== 统计信息 ===${NC}"
echo -e "总大小: ${GREEN}$total_size${NC}"
echo -e "子目录数: ${YELLOW}$subdir_count${NC}"
echo -e "文件数: ${YELLOW}$file_count${NC}"
