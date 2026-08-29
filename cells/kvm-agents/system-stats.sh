#!/usr/bin/env bash

# Keep the status command lightweight and independent of optional tmux plugins.
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle1=$((idle + iowait))
sleep 0.1
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle2=$((idle + iowait))

cpu=$(awk -v total="$((total2 - total1))" -v idle="$((idle2 - idle1))" \
  'BEGIN { if (total > 0) printf "%.0f", (total - idle) * 100 / total; else print "0" }')
mem=$(free -k | awk '/^Mem:/ {
  printf "%.1f GB/%.1f GB (%.0f%%)", $3 / 1024 / 1024, $2 / 1024 / 1024, $3 * 100 / $2
}')
gpu=$(timeout 1 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null \
  | awk '{ sum += $1; count++ } END { if (count) printf "%.0f", sum / count; else print "n/a" }')

printf 'CPU %s%% | GPU %s%% | MEM %s' "$cpu" "$gpu" "$mem"
