#!/bin/bash
# cheer_zh.sh — 中文语音鼓励
# 优先 macOS say → espeak → 打印文字
# 语音受 CHEERER_VOICE 环境变量控制（on/off/true/false）
# CHEERER_DUMB=true 时不输出任何 ANSI escape code
#
# 风格：技术梗风 + 二次元风 + 幽默风，均匀分布
# 规则：每条消息必须包含至少一个技术具体性词汇或程序员梗

MESSAGES=(
  # 技术梗风（第1-5条）
  "又干掉一个 bug，代码库感谢你的守护！"
  "代码合并，天下太平！这个 commit 写进史册了！"
  "测试全绿！你的代码连 CI 都不忍心拦它！"
  "这波重构绝了，技术债又少了一大截！"
  "Pull Request 通过，代码质量又上了一个台阶！"
  # 二次元风（第6-10条）
  "さすが！又一个任务消灭了，神级程序员降临！"
  "代码已入库，世界因你的 commit 更美好ヾ(≧▽≦*)o"
  "任务完成！就算深夜 debug 也无法阻挡你的传说！"
  "你的代码写得比 galgame 剧情还丝滑，了不起！"
  "CPU 都被你的效率感动了，芯片默默流下一行注释！"
  # 幽默风（第11-13条）
  "函数写好了？栈帧表示很欣慰！"
  "这段逻辑连 GPT 看了都要叫你 Senior！"
  "又一个 TODO 变成了 DONE，待办列表在颤抖！"
)

MSG="${MESSAGES[$((RANDOM % ${#MESSAGES[@]}))]}"
if [[ -n "${CHEERER_MILESTONE_MSG:-}" ]]; then
  MSG="$MSG ${CHEERER_MILESTONE_MSG}"
fi

# 输出文字鼓励（dumb terminal 模式不加颜色）
CHEERER_DUMB="${CHEERER_DUMB:-false}"
if [[ "$CHEERER_DUMB" == "true" ]]; then
  echo "🎉 $MSG"
else
  echo -e "\033[1;32m🎉 $MSG\033[0m"
fi

# 语音播放（受 CHEERER_VOICE 控制，后台执行，静默失败）
CHEERER_VOICE="${CHEERER_VOICE:-on}"
if [[ "$CHEERER_VOICE" == "off" ]] || [[ "$CHEERER_VOICE" == "false" ]]; then
  exit 0
fi

if command -v say >/dev/null 2>&1; then
  # macOS：后台执行，不阻塞主流程（ADR-002）
  say -v "Ting-Ting" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  # Linux espeak：后台执行
  espeak -v zh "$MSG" >/dev/null 2>&1 & disown
fi
# 其他平台：仅打印文字（已在上方 echo，三级降级完成）

exit 0
