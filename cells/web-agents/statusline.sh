#!/bin/bash
# Claude Code statusline
# Format: [Model] effort | ctx:X% | 5h:X% (resets HH:MM) | 7d:X% (resets Ddd Mon DD HH:MM)

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // "--"')

ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx" ]; then
  ctx=$(printf '%.0f' "$ctx")
else
  ctx="--"
fi

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five_pct" ]; then
  five_pct=$(printf '%.0f' "$five_pct")
else
  five_pct="--"
fi
if [ -n "$five_reset" ]; then
  five_time=$(date -d "@$five_reset" +%H:%M 2>/dev/null)
  [ -z "$five_time" ] && five_time="--"
else
  five_time="--"
fi

week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_pct" ]; then
  week_pct=$(printf '%.0f' "$week_pct")
else
  week_pct="--"
fi
if [ -n "$week_reset" ]; then
  week_time=$(date -d "@$week_reset" '+%a %b %d %H:%M' 2>/dev/null)
  [ -z "$week_time" ] && week_time="--"
else
  week_time="--"
fi

printf '[%s] %s | ctx:%s%% | 5h:%s%% (resets %s) | 7d:%s%% (resets %s)\n' \
  "$model" "$effort" "$ctx" "$five_pct" "$five_time" "$week_pct" "$week_time"
