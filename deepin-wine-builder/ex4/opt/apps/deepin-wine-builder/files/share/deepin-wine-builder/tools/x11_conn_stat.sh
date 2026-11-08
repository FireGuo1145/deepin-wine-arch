#!/bin/bash

echo "X11连接数统计 - Top 5 进程"
echo "============================================"

# 提取所有本地端口号
ports=$(ss -p 2>/dev/null | grep X11-unix | awk '{print $6}' | sed 's/.*://')

declare -A pid_count

for port in $ports; do
    # 查找连接到该显示端口的进程
    while IFS= read -r line; do
        # 提取PID
        pid=$(grep -o 'pid=[0-9]*' <<<"$line" | head -n1 | cut -d= -f2)
        [ -z "$pid" ] && continue

        # 获取进程名
        pname=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d '\n')
        [ -z "$pname" ] && pname="unknown"

        # 统计
        key="$pid:$pname"
        ((pid_count["$key"]++))
    done < <(ss -p 2>/dev/null | grep "$port " | grep -v X11-unix)
done

# 计算总连接数
total_connections=0
for count in "${pid_count[@]}"; do
    ((total_connections += count))
done

echo "总连接数: $total_connections"
echo "X11限制连接数: 255"
echo ""
echo "Top 5 进程（按连接数从高到低）："
echo "--------------------------------------------"

# 按连接数从高到低排列，只输出前5个
count=0
for key in "${!pid_count[@]}"; do
    echo "${pid_count[$key]} $key"
done | sort -nr | while read cnt key; do
    ((count++))
    [ $count -gt 5 ] && break
    pid="${key%%:*}"
    pname="${key##*:}"
    echo "  $count. $pname (PID: $pid) - $cnt 连接"
done

echo ""
echo "============================================"
echo "提示: 连接数过多的进程可能导致X11服务器达到最大客户端限制" 

