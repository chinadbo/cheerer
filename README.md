# 🎉 cheerer — Claude Code 鼓励师

每当 Claude Code 完成任务时，在终端播放像素动画 + 语音鼓励，让编码更快乐！

## ✨ 功能

- 🏀 投篮像素动画（帧动画，ANSI 字符艺术）
- 💃 二次元跳舞动画
- 🎆 烟花爆炸动画
- 🔊 多语言语音鼓励（中文 / 英文 / 日文）
- 🎲 随机选择动画 + 语言，每次都不一样

## 📦 安装

### 方式一：Claude Code 插件（推荐）

```bash
# 克隆到本地
git clone https://github.com/your-org/cheerer.git ~/.cheerer

# 给所有脚本加执行权限
chmod +x ~/.cheerer/scripts/*.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh

# 在 Claude Code 中注册插件
# 将插件路径添加到 Claude Code 配置
```

### 方式二：手动 Hook（适合测试）

在 Claude Code 配置文件（`~/.claude/settings.json`）中添加：

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "/path/to/cheerer/scripts/cheer.sh"
      }
    ],
    "TaskCompleted": [
      {
        "command": "/path/to/cheerer/scripts/cheer.sh"
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

## 🛠️ 技术实现

- **纯 Shell 实现**，零外部依赖
- **ANSI escape code** 控制颜色 + 光标位置
- **帧动画**：利用光标回退 (`\033[11A`) 原位重绘
- **语音降级**：macOS `say` → `espeak` → 纯文字
- **动画时长**：约 2~3 秒，不阻塞工作流

## 📁 目录结构

```
cheerer/
├── .claude-plugin/
│   └── plugin.json          # 插件 manifest
├── hooks/
│   └── hooks.json           # Hook 配置
├── scripts/
│   ├── cheer.sh             # 主入口（随机动画 + 语言）
│   ├── animations/
│   │   ├── basketball.sh    # 投篮像素动画 ⭐完整实现
│   │   ├── dance.sh         # 二次元跳舞
│   │   └── fireworks.sh     # 烟花
│   └── voices/
│       ├── cheer_zh.sh      # 中文鼓励
│       ├── cheer_en.sh      # 英文鼓励
│       └── cheer_ja.sh      # 日文鼓励
└── README.md
```

## 🔧 自定义扩展

### 添加新动画

1. 在 `scripts/animations/` 创建新的 `.sh` 文件
2. 在 `scripts/cheer.sh` 的 `ANIMS` 数组中加入名称

### 添加新语言

1. 在 `scripts/voices/` 创建 `cheer_XX.sh`
2. 在 `scripts/cheer.sh` 中添加对应 `case` 分支

## 📝 License

MIT © guli-swe
