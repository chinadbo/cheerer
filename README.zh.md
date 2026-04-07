# 🎉 cheerer — Claude Code 鼓励师

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)


**语言：** [English](README.md) | 中文 | [日本語](README.ja.md)


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

### 方式一：Claude Code Plugin（一行命令，推荐）⭐

需要 Claude Code。直接从 GitHub 安装，无需手动克隆：

```bash
claude plugin install github:chinadbo/cheerer
```

或在 Claude Code 会话中：

```
/plugin install github:chinadbo/cheerer
```

安装后自动注册 Hook，立即生效。

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
            "command": "~/.cheerer/scripts/cheer.sh"
          }
        ]
      }
    ]
  }
}
```

## ⚙️ 配置

### 方式一：交互式配置（Plugin 安装推荐）

启用插件时，Claude Code 会引导你完成配置：

```
/plugin enable cheerer
> 语音语言（zh / en / ja）：zh
> 动画类型（random / basketball / dance / fireworks）：random
> 启用语音（on / off）：on
```

配置自动保存，跨会话持久有效。

### 方式二：环境变量

在 `~/.bashrc` / `~/.zshrc` 或 `.claude/settings.json` 中设置：

| 变量 | 说明 | 可选值 | 默认值 |
|------|------|--------|---------|
| `CHEERER_LANG` | 语音语言 | `zh` / `en` / `ja` | `zh` |
| `CHEERER_ANIM` | 动画类型 | `basketball` / `dance` / `fireworks` / `random` | `random` |
| `CHEERER_ENABLED` | 主开关 | `true` / `false` | `true` |
| `CHEERER_VOICE` | 语音开关 | `on` / `off` | `on` |
| `CHEERER_COOLDOWN` | 两次触发的冷却时间（秒）| 正整数 | `3` |

> `CHEERER_*` 环境变量优先级高于 plugin userConfig 配置。

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
