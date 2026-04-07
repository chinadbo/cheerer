#!/bin/bash
# cheer.sh — cheerer 主入口脚本
# 当 Claude Code 完成任务时触发（Stop / TaskCompleted Hook），随机播放像素动画 + 语音鼓励
#
# ┌─────────────────────────────────────────────────────────────────┐
# │  环境变量配置（全部有默认值，可选设置）                          │
# │                                                                 │
# │  CHEERER_ENABLED   总开关      true|false     默认: true        │
# │  CHEERER_LANG      语言        zh|en|ja       默认: zh          │
# │  CHEERER_ANIM      动画风格    basketball|    默认: random      │
# │                               dance|         （随机选择）       │
# │                               fireworks|                       │
# │                               random                           │
# │  CHEERER_VOICE     语音开关    on|off|true|   默认: on          │
# │                               false                            │
# │  CHEERER_COOLDOWN  冷却秒数    正整数          默认: 3           │
# │                                                                 │
# │  冷却机制：两次触发间隔 < CHEERER_COOLDOWN 秒时，               │
# │  第二次跳过动画，仅输出文字鼓励。基于 /tmp/cheerer_last_trigger  │
# └─────────────────────────────────────────────────────────────────┘

# 所有路径均返回 0，不让 cheerer 报错影响 Claude Code
set +e

# ── 1. 总开关检查（在任何 I/O 操作之前）──────────────
CHEERER_ENABLED="${CHEERER_ENABLED:-true}"
if [[ "$CHEERER_ENABLED" == "false" ]]; then
  exit 0
fi

# ── 输出重定向到 /dev/tty（Claude Code hooks 会吞掉 stdout）──────
# 如果 stdout 不是 tty，强制输出到 /dev/tty
if [[ ! -t 1 ]] && { exec 3>/dev/tty; } 2>/dev/null; then
  exec 1>/dev/tty 3>&-
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANIM_DIR="$SCRIPT_DIR/animations"
VOICE_DIR="$SCRIPT_DIR/voices"

# ── 2. 读取配置 ───────────────────────────────────────
CHEERER_LANG="${CHEERER_LANG:-zh}"
CHEERER_ANIM="${CHEERER_ANIM:-random}"
CHEERER_VOICE="${CHEERER_VOICE:-on}"
CHEERER_COOLDOWN="${CHEERER_COOLDOWN:-3}"

# 语言合法性校验
case "$CHEERER_LANG" in
  zh|en|ja) ;;
  *) CHEERER_LANG="zh" ;;
esac

# ── 3. dumb terminal 检测 ─────────────────────────────
# 检测 dumb terminal 或无 TERM 时，禁用所有 ANSI（含颜色）
CHEERER_DUMB=false
if [[ "${TERM:-}" == "dumb" ]] || [[ -z "${TERM:-}" ]]; then
  CHEERER_DUMB=true
else
  # 检测颜色支持（tput colors < 8 视为不支持）
  COLOR_COUNT=$(tput colors 2>/dev/null || echo 0)
  if [[ "$COLOR_COUNT" -lt 8 ]] 2>/dev/null; then
    CHEERER_DUMB=true
  fi
fi
export CHEERER_DUMB

# ── 4. 冷却机制检查 ───────────────────────────────────
COOLDOWN_FILE="/tmp/cheerer_last_trigger"
IN_COOLDOWN=false
CURRENT_TIME=$(date +%s 2>/dev/null || echo 0)

if [[ -f "$COOLDOWN_FILE" ]]; then
  LAST_RUN=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  if [[ -n "$LAST_RUN" ]] && [[ "$LAST_RUN" =~ ^[0-9]+$ ]]; then
    DIFF=$(( CURRENT_TIME - LAST_RUN ))
    if [[ "$DIFF" -lt "$CHEERER_COOLDOWN" ]] 2>/dev/null; then
      IN_COOLDOWN=true
    fi
  fi
fi

# 更新时间戳
echo "$CURRENT_TIME" > "$COOLDOWN_FILE" 2>/dev/null || true

# ── 5. 选择动画 ───────────────────────────────────────
ANIMS=(basketball dance fireworks)
if [[ "$CHEERER_ANIM" == "random" ]] || [[ -z "$CHEERER_ANIM" ]]; then
  ANIM="${ANIMS[$((RANDOM % ${#ANIMS[@]}))]}"
else
  ANIM="$CHEERER_ANIM"
fi
ANIM_SCRIPT="$ANIM_DIR/$ANIM.sh"

# ── 6. 播放动画（冷却中跳过，dumb terminal 跳过）──────
if [[ "$IN_COOLDOWN" == "false" ]] && [[ "$CHEERER_DUMB" == "false" ]]; then
  if [[ -f "$ANIM_SCRIPT" ]]; then
    bash "$ANIM_SCRIPT"
  else
    echo "⚠️  动画脚本不存在: $ANIM_SCRIPT" >&2
  fi
fi

# ── 7. 语音/文字鼓励 ──────────────────────────────────
VOICE_SCRIPT="$VOICE_DIR/cheer_${CHEERER_LANG}.sh"

if [[ -f "$VOICE_SCRIPT" ]]; then
  CHEERER_VOICE="$CHEERER_VOICE" CHEERER_DUMB="$CHEERER_DUMB" bash "$VOICE_SCRIPT"
else
  # 终极 fallback：内联鼓励
  if [[ "$CHEERER_DUMB" == "true" ]]; then
    echo "🎉 任务完成！代码合并，天下太平！"
  else
    echo -e "\033[1;32m🎉 任务完成！代码合并，天下太平！\033[0m"
  fi
fi

exit 0
