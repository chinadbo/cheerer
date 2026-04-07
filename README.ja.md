# 🎉 cheerer — Claude Code 応援プラグイン

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)

Claude Code がタスクを完了すると、cheerer はターミナルでピクセルアニメーションと多言語の音声応援を再生し、コーディングをもっと楽しくします。

## ✨ 主な機能

- 🏀 ANSI フレーム描画によるバスケットボール風ピクセルアニメーション
- 💃 ダンスアニメーション
- 🎆 花火アニメーション
- 🔊 多言語の音声応援（中国語 / 英語 / 日本語）
- 🎲 アニメーションと言語をランダムに選択し、毎回違う演出を提供

## 🎬 デモについて

Claude Code がタスクを完了すると、ターミナル上で短いピクセルアニメーションが再生され、対応する言語で応援メッセージが表示されます。ここではひとまず説明文のみを掲載しており、後日 GIF デモを追加する予定です。

## 📦 インストール

### 方法 1: Claude Code プラグインとして使う（推奨）

```bash
# リポジトリをローカルに clone
git clone https://github.com/chinadbo/cheerer.git ~/.cheerer

# メインスクリプトと各サブディレクトリ内のスクリプトに実行権限を付与
chmod +x ~/.cheerer/scripts/cheer.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh
```

Claude Code の `~/.claude/settings.json` に hooks を設定してください。

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

### 方法 2: 手動で Hook を設定する（ローカル検証向け）

`~/.cheerer` 以外の場所に配置する場合は、コマンドのパスをご自身の環境に合わせて変更し、`~/.claude/settings.json` に次のように設定してください。

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

## 🚀 使い方

### 直接実行する（テスト用）

```bash
# ランダムなアニメーション + 中国語の応援
./scripts/cheer.sh

# 言語を指定
./scripts/cheer.sh en    # 英語
./scripts/cheer.sh zh    # 中国語（デフォルト）
./scripts/cheer.sh ja    # 日本語

# 環境変数でアニメーションを指定
CHEERER_ANIM=basketball ./scripts/cheer.sh
CHEERER_ANIM=dance ./scripts/cheer.sh
CHEERER_ANIM=fireworks ./scripts/cheer.sh

# 環境変数で言語を指定（最優先）
CHEERER_LANG=en ./scripts/cheer.sh
```

### アニメーション単体で実行する

```bash
bash scripts/animations/basketball.sh
bash scripts/animations/dance.sh
bash scripts/animations/fireworks.sh
```

### 音声スクリプト単体で実行する

```bash
bash scripts/voices/cheer_zh.sh
bash scripts/voices/cheer_en.sh
bash scripts/voices/cheer_ja.sh
```

## ⚙️ 環境変数

| 変数 | 説明 | 値 |
|------|------|--------|
| `CHEERER_LANG` | 言語（CLI 引数より優先） | `zh` / `en` / `ja` |
| `CHEERER_ANIM` | アニメーションを固定指定 | `basketball` / `dance` / `fireworks` |
| `CHEERER_ENABLED` | 全体の有効 / 無効切り替え | `true` / `false` |
| `CHEERER_VOICE` | 音声の有効 / 無効切り替え | `on` / `off` / `true` / `false` |
| `CHEERER_COOLDOWN` | 再発火までのクールダウン秒数 | 正の整数 |

## 🛠️ 技術メモ

- **Pure Shell 実装**で、実行時の外部依存は不要です
- **ANSI エスケープコード**で色とカーソル移動を制御します
- **フレームアニメーション**はカーソル巻き戻し（`\033[11A`）でその場描画します
- **音声フォールバック**は macOS `say` → `espeak` → プレーンテキストの順です
- **アニメーション時間**は約 2〜3 秒で、作業フローを妨げにくい設計です
- **端末互換性**として、dumb terminal を自動検知して穏やかに降格します

## 📁 ディレクトリ構成

```text
cheerer/
├── .claude-plugin/
│   └── plugin.json          # プラグイン manifest
├── hooks/
│   └── hooks.json           # Hook 設定
├── scripts/
│   ├── cheer.sh             # メインエントリ（ランダムなアニメーション + 言語）
│   ├── animations/
│   │   ├── basketball.sh    # バスケットボールアニメーション
│   │   ├── dance.sh         # ダンスアニメーション
│   │   └── fireworks.sh     # 花火アニメーション
│   └── voices/
│       ├── cheer_zh.sh      # 中国語の応援
│       ├── cheer_en.sh      # 英語の応援
│       └── cheer_ja.sh      # 日本語の応援
├── README.md
├── README.en.md
└── README.ja.md
```

## 🔧 カスタマイズ

### 新しいアニメーションを追加する

1. `scripts/animations/` に新しい `.sh` ファイルを作成します
2. `scripts/cheer.sh` の `ANIMS` 配列に名前を追加します
3. `bash scripts/cheer.sh test` を実行して動作確認します

### 新しい言語を追加する

1. `scripts/voices/` に `cheer_XX.sh` を作成します
2. `scripts/cheer.sh` に対応する言語処理を追加します
3. `bash scripts/cheer.sh test` を実行して出力を確認します

## 📝 ライセンス

MIT © chinadbo
