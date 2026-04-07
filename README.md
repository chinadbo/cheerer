# 🎉 cheerer — Claude Code 鼓励师

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)

每当 Claude Code 完成任务时，在终端播放像素动画 + 多语言语音鼓励，让编码更快乐！

## ✨ 功能

- 🏀 投篮像素动画（帧动画，ANSI 字符艺术）
- 💃 二次元跳舞动画
- 🎆 烟花爆炸动画
- 🔊 多语言语音鼓励（中文 / 英文 / 日文）
- 🎲 随机选择动画 + 语言，每次都不一样

## 🎬 演示说明

当 Claude Code 完成任务后，终端会即时播放一段像素动画，并用对应语言送上一句鼓励。这里先保留文字说明占位，后续会补充 GIF 演示。

## 📦 安装

### 方式一：Claude Code 插件（推荐）

```bash
# 克隆到本地
git clone https://github.com/chinadbo/cheerer.git ~/.cheerer

# 给主脚本和子目录脚本加执行权限
chmod +x ~/.cheerer/scripts/cheer.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh
```

在 Claude Code 的 `~/.claude/settings.json` 中配置 hooks：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.cheerer/scripts/cheer.sh"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.cheerer/scripts/cheer.sh"
          }
        ]
      }
    ]
  }
}
```

### 方式二：手动 Hook（适合本地测试）

如果你不是按 `~/.cheerer` 安装，也可以把脚本路径替换成你自己的本地路径，然后在 `~/.claude/settings.json` 中这样配置：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/cheerer/scripts/cheer.sh"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/cheerer/scripts/cheer.sh"
          }
        ]
      }
    ]
  }
}
```

## 🚀 使用方法

### 直接运行（测试）

```bash
# 随机动画 + 中文鼓励
./scripts/cheer.sh

# 指定语言
./scripts/cheer.sh en    # 英文
./scripts/cheer.sh zh    # 中文（默认）
./scripts/cheer.sh ja    # 日文

# 指定动画（环境变量）
CHEERER_ANIM=basketball ./scripts/cheer.sh
CHEERER_ANIM=dance ./scripts/cheer.sh
CHEERER_ANIM=fireworks ./scripts/cheer.sh

# 指定语言（环境变量，优先级最高）
CHEERER_LANG=en ./scripts/cheer.sh
```

### 单独运行动画

```bash
bash scripts/animations/basketball.sh
bash scripts/animations/dance.sh
bash scripts/animations/fireworks.sh
```

### 单独运行语音

```bash
bash scripts/voices/cheer_zh.sh
bash scripts/voices/cheer_en.sh
bash scripts/voices/cheer_ja.sh
```

## ⚙️ 环境变量

| 变量 | 说明 | 可选值 |
|------|------|--------|
| `CHEERER_LANG` | 语言（优先级高于参数） | `zh` / `en` / `ja` |
| `CHEERER_ANIM` | 指定动画（不设则随机） | `basketball` / `dance` / `fireworks` |
| `CHEERER_ENABLED` | 总开关 | `true` / `false` |
| `CHEERER_VOICE` | 是否启用语音 | `on` / `off` / `true` / `false` |
| `CHEERER_COOLDOWN` | 两次触发之间的冷却秒数 | 正整数 |

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
├── hooks/
│   └── hooks.json           # Hook 配置
├── scripts/
│   ├── cheer.sh             # 主入口（随机动画 + 语言）
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
└── README.ja.md
```

## 🔧 自定义扩展

### 添加新动画

1. 在 `scripts/animations/` 创建新的 `.sh` 文件
2. 在 `scripts/cheer.sh` 的 `ANIMS` 数组中加入名称
3. 运行 `bash scripts/cheer.sh test` 验证脚本可正常执行

### 添加新语言

1. 在 `scripts/voices/` 创建 `cheer_XX.sh`
2. 在 `scripts/cheer.sh` 中添加对应语言处理
3. 运行 `bash scripts/cheer.sh test` 验证输出

## 📝 License

MIT © chinadbo
