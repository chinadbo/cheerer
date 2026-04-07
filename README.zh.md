# 🎉 cheerer — Claude Code 鼓励师

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)

**语言：** [English](README.md) | 中文 | [日本語](README.ja.md)

每当 Claude Code 完成任务时，在终端播放像素动画 + 多语言语音鼓励，让编码更快乐！

## ✨ 功能

- 🏀 投篮、跳舞、烟花三种终端动画
- 🔊 多语言语音鼓励（中文 / 英文 / 日文）
- 🎲 随机选择动画，也可以强制指定动画
- 🚀 Epic 模式会依次播放三段动画
- 📊 触发统计与里程碑庆祝（`--stats`、里程碑烟花）
- 📝 支持从 `custom-messages.txt` 加载自定义鼓励语
- 🖥️ 自动 dumb terminal 降级与按会话隔离的冷却机制

## 🎬 演示说明

当 Claude Code 完成任务后，终端会即时播放一段像素动画，并用对应语言送上一句鼓励。这里先保留文字说明占位，后续会补充 GIF 演示。

## 📦 安装

### 方式一：将 cheerer 作为 Marketplace 添加（推荐）⭐

需要 Claude Code。先把这个仓库添加为插件 Marketplace，再从该 Marketplace 安装 `cheerer` 插件：

```bash
claude plugin marketplace add chinadbo/cheerer
claude plugin install cheerer@cheerer
```

或在 Claude Code 会话中：

```text
/plugin marketplace add chinadbo/cheerer
/plugin install cheerer@cheerer
```

如果是在当前会话中安装，随后执行 `/reload-plugins`。

### 方式二：Plugin Marketplace（团队使用）

在你的 `marketplace.json` 中加入 cheerer：

```json
{
  "name": "your-marketplace",
  "plugins": [
    {
      "name": "cheerer",
      "source": {
        "source": "github",
        "repo": "chinadbo/cheerer"
      },
      "description": "任务完成时播放像素动画 + 语音鼓励"
    }
  ]
}
```

或直接将 chinadbo/cheerer 作为单插件 Marketplace 添加：

```bash
claude plugin marketplace add chinadbo/cheerer
claude plugin install cheerer@cheerer
```

### 方式三：手动 Hook（不使用 Claude Code 插件系统）

```bash
git clone https://github.com/chinadbo/cheerer.git ~/.cheerer
chmod +x ~/.cheerer/scripts/cheer.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh
chmod +x ~/.cheerer/bin/cheer
```

在 `~/.claude/settings.json` 中添加：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.cheerer/scripts/cheer.sh",
            "async": true,
            "statusMessage": "🎉 Cheering..."
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.cheerer/scripts/cheer.sh",
            "async": true,
            "statusMessage": "🎉 Cheering..."
          }
        ]
      }
    ]
  }
}
```

## ⚙️ 配置

### 方式一：插件配置

如果 Claude Code 在 `/plugin enable cheerer` 时提示你填写插件配置，可以设置：

```
/plugin enable cheerer
> 语音语言（zh / en / ja）：zh
> 动画类型（random / basketball / dance / fireworks / epic）：random
> 启用语音（on / off）：on
```

如果没有出现交互提示，也可以直接通过环境变量完成同样的配置。

### 方式二：环境变量

在 `~/.bashrc` / `~/.zshrc` 或 `.claude/settings.json` 中设置：

| 变量 | 说明 | 可选值 | 默认值 |
|------|------|--------|---------|
| `CHEERER_ENABLED` | 主开关 | `true` / `false` | `true` |
| `CHEERER_LANG` | 语音语言 | `zh` / `en` / `ja` | `zh` |
| `CHEERER_ANIM` | 动画类型 | `basketball` / `dance` / `fireworks` / `epic` / `random` | `random` |
| `CHEERER_VOICE` | 语音开关 | `on` / `off` / `true` / `false` | `on` |
| `CHEERER_DUMB` | 强制纯文本降级或保持自动检测 | `auto` / `true` / `false` | `auto` |
| `CHEERER_MODE` | 输出模式 | `auto` / `full` / `text` | `auto` |
| `CHEERER_COOLDOWN` | 两次触发的冷却时间（秒） | 正整数 | `3` |
| `CHEERER_EPIC_THRESHOLD` | 任务时长达到该秒数后自动进入 Epic 模式 | 正整数 | `60` |
| `CHEERER_EPIC` | 单次运行强制开启 Epic 模式 | `true` / `false` | `false` |
| `CHEERER_CUSTOM_ONLY` | 有自定义文案时仅使用自定义文案 | `true` / `false` | `false` |

> `CHEERER_*` 环境变量优先级高于插件 `userConfig` 配置。

### 运行时行为

- `CHEERER_MODE=auto` 时，`TaskCompleted` 会播放动画，`Stop` 默认只输出文字/语音。
- `CHEERER_MODE=full` 时，所有 Hook 都播放动画。
- `CHEERER_MODE=text` 时，始终跳过动画，只输出鼓励文字/语音。
- `CHEERER_ANIM=epic`、`CHEERER_EPIC=true`，或任务时长达到 `CHEERER_EPIC_THRESHOLD` 时，会依次播放三段动画。
- `CHEERER_COOLDOWN` 的实际最小值为 1 秒，即使设置为 `0` 也会按 1 秒处理。
- `CHEERER_DUMB=auto` 为默认行为；cheerer 也会自动检测 dumb terminal 和低色彩终端。

## 🚀 直接使用

在仓库目录中可直接运行：

```bash
# 主脚本
bash scripts/cheer.sh
CHEERER_LANG=en bash scripts/cheer.sh
CHEERER_LANG=ja CHEERER_VOICE=off bash scripts/cheer.sh
CHEERER_ANIM=fireworks bash scripts/cheer.sh
CHEERER_ANIM=epic bash scripts/cheer.sh
CHEERER_MODE=text bash scripts/cheer.sh
CHEERER_DUMB=true bash scripts/cheer.sh

# 包装命令
bash bin/cheer --epic
bash bin/cheer --stats
```

`bin/cheer` 目前只支持两个 flag：

- `--epic` —— 强制 Epic 模式（投篮 + 跳舞 + 烟花）
- `--stats` —— 输出总触发次数、已达成里程碑、最后一次触发时间

## 📁 状态与数据文件

默认情况下，cheerer 会把插件数据保存到 `${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}`：

- `stats.json` —— 记录总触发次数、最后触发时间、里程碑历史
- `custom-messages.txt` —— 可选的自定义鼓励文案，一行一条，`#` 开头表示注释

冷却状态单独保存在 `/tmp/cheerer_last_trigger_${CLAUDE_SESSION_ID:-default}`。

当前里程碑阈值为 10、25、50、100、250、500、1000 次触发。命中里程碑时会追加奖杯提示，并强制播放烟花动画。

## 🛠️ 技术实现

- **纯 Shell 实现**，零外部依赖
- **ANSI escape code** 控制颜色 + 光标位置
- **帧动画**：利用光标回退 (`\033[11A`) 原位重绘
- **语音降级**：macOS `say` → `espeak` → 纯文字
- **动画时长**：约 2~3 秒，不阻塞工作流
- **终端兼容**：自动识别 dumb terminal 并降级输出

## 📁 目录结构

```text
cheerer/
├── .claude-plugin/
│   └── plugin.json          # 插件 manifest
├── bin/
│   └── cheer                # 包装命令（--epic、--stats）
├── hooks/
│   └── hooks.json           # Hook 配置
├── scripts/
│   ├── cheer.sh             # 主入口（Hook 路由 + 状态 + 统计）
│   ├── animations/
│   │   ├── basketball.sh    # 投篮像素动画
│   │   ├── dance.sh         # 二次元跳舞
│   │   └── fireworks.sh     # 烟花
│   └── voices/
│       ├── cheer_zh.sh      # 中文鼓励
│       ├── cheer_en.sh      # 英文鼓励
│       └── cheer_ja.sh      # 日文鼓励
├── README.md
├── README.en.md
├── README.zh.md
└── README.ja.md
```

## 🔧 自定义扩展

### 添加新动画

1. 在 `scripts/animations/` 创建新的 `.sh` 文件
2. 在 `scripts/cheer.sh` 的 `ANIMS` 数组中加入名称
3. 运行 `bash scripts/cheer.sh` 或 `CHEERER_ANIM=<name> bash scripts/cheer.sh` 验证脚本可正常执行

### 添加新语言

1. 在 `scripts/voices/` 创建 `cheer_XX.sh`
2. 在 `scripts/cheer.sh` 中添加对应语言处理
3. 运行 `CHEERER_LANG=<code> bash scripts/cheer.sh` 验证输出

### 添加自定义鼓励语

创建 `${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}/custom-messages.txt`：

```text
冲冲冲！
这波提交很稳。
测试全绿，值得庆祝。
```

如果你希望只使用自定义文案，可设置 `CHEERER_CUSTOM_ONLY=true`。

## 📝 License

MIT © chinadbo
