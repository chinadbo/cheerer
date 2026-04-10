# 🎉 cheerer — Claude Code 応援プラグイン

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)

**言語：** [English](README.md) | [中文](README.zh.md) | 日本語

Claude Code がタスクを完了すると、cheerer はターミナルでピクセルアニメーションと多言語の音声応援を再生し、コーディングをもっと楽しくします。

## ✨ 主な機能

- 🏀 バスケットボール、ダンス、花火の3種類のターミナルアニメーション
- 🔊 多言語の音声応援（中国語 / 英語 / 日本語）
- 🎲 アニメーションをランダム選択、または固定指定可能
- 🚀 Epic モードでは3つのアニメーションを連続再生
- 📊 トリガー統計とマイルストーン演出（`--stats`、花火演出）
- 📝 `custom-messages.txt` からカスタム応援文を読み込み可能
- 🖥️ dumb terminal の自動降格とセッション単位クールダウンに対応

## 🎬 デモについて

Claude Code がタスクを完了すると、ターミナル上で短いピクセルアニメーションが再生され、対応する言語で応援メッセージが表示されます。ここではひとまず説明文のみを掲載しており、後日 GIF デモを追加する予定です。

## 📦 インストール

### 方法1：cheerer を Marketplace として追加（推奨）⭐

Claude Code が必要です。まずこのリポジトリをプラグイン Marketplace として追加し、その Marketplace から `cheerer` プラグインをインストールします：

```bash
claude plugin marketplace add chinadbo/cheerer
claude plugin install cheerer@cheerer
```

Claude Code セッション内から：

```text
/plugin marketplace add chinadbo/cheerer
/plugin install cheerer@cheerer
```

現在のセッション中にインストールした場合は、その後 `/reload-plugins` を実行してください。

### 方法2：Plugin Marketplace（チーム向け）

`marketplace.json` に cheerer を追加：

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
      "description": "タスク完了時にアニメーション＋音声応援"
    }
  ]
}
```

または chinadbo/cheerer を直接 Marketplace として追加：

```bash
claude plugin marketplace add chinadbo/cheerer
claude plugin install cheerer@cheerer
```

### 方法3：手動 Hook 設定（Claude Code プラグインシステムなし）

```bash
git clone https://github.com/chinadbo/cheerer.git ~/.cheerer
chmod +x ~/.cheerer/scripts/cheer.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh
chmod +x ~/.cheerer/bin/cheer
```

`~/.claude/settings.json` に追加：

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

## ⚙️ 設定

### 方法1：プラグイン設定

Claude Code が `/plugin enable cheerer` 中に設定入力を表示した場合、次の値を設定できます：

```text
/plugin enable cheerer
> 音声言語（zh / en / ja）: ja
> アニメーション（random / basketball / dance / fireworks / epic）: random
> 音声出力（on / off）: on
> 応援スタイル（adaptive / balanced / hype / cozy）: adaptive
> 応援の強さ（soft / normal / high）: normal
```

入力プロンプトが表示されない場合は、同じ設定を環境変数で指定してください。

### 方法2：環境変数

`~/.bashrc` / `~/.zshrc` または `.claude/settings.json` に設定：

| 変数 | 説明 | 値 | デフォルト |
|------|------|--------|---------|
| `CHEERER_ENABLED` | マスタースイッチ | `true` / `false` | `true` |
| `CHEERER_LANG` | 音声言語 | `zh` / `en` / `ja` | `zh` |
| `CHEERER_ANIM` | アニメーション | `basketball` / `dance` / `fireworks` / `epic` / `random` | `random` |
| `CHEERER_VOICE` | 音声出力 | `on` / `off` / `true` / `false` | `on` |
| `CHEERER_DUMB` | テキストのみを強制するか自動判定を使う | `auto` / `true` / `false` | `auto` |
| `CHEERER_MODE` | 出力モード | `auto` / `full` / `text` | `auto` |
| `CHEERER_COOLDOWN` | トリガー間クールダウン（秒） | 正の整数 | `3` |
| `CHEERER_EPIC_THRESHOLD` | この秒数以上で Epic モードを自動有効化 | 正の整数 | `60` |
| `CHEERER_EPIC` | 単発で Epic モードを強制 | `true` / `false` | `false` |
| `CHEERER_CUSTOM_ONLY` | カスタムメッセージのみを使う | `true` / `false` | `false` |
| `CHEERER_STYLE` | 応援スタイル | `adaptive` / `balanced` / `hype` / `cozy` | `adaptive` |
| `CHEERER_INTENSITY` | 応援の強さ | `soft` / `normal` / `high` | `normal` |

> `CHEERER_*` 環境変数は plugin userConfig より優先されます。

### 実行時の挙動

- `CHEERER_MODE=auto` は `Stop` Hook ではテキストのみ、`TaskCompleted` Hook ではアニメーションを再生します。ただし `CHEERER_INTENSITY=high` のときは `Stop` Hook でもアニメーションします。
- `CHEERER_MODE=full` は常にアニメーションを再生します。
- `CHEERER_MODE=text` は常にアニメーションをスキップします。
- `CHEERER_ANIM=epic`、`CHEERER_EPIC=true`、またはタスク時間が `CHEERER_EPIC_THRESHOLD` 以上のとき、3つのアニメーションを連続再生します。
- `CHEERER_COOLDOWN` は `0` を指定しても実効最小値は 1 秒です。
- クールダウン中でもテキスト/音声出力は継続し、抑制されるのはアニメーションのみです。
- `CHEERER_DUMB=auto` はデフォルト動作です。cheerer は dumb terminal や空の `TERM` も自動検知して降格します。
- `CHEERER_STYLE=adaptive` は Hook 種別、タスク時間、マイルストーン、直近履歴を使って応援トーンを切り替えます。
- `CHEERER_INTENSITY=soft` は軽い完了を控えめにし、`high` は祝福をより勢いよくします。`CHEERER_MODE=auto` では `Stop` Hook のアニメーションも有効になります。
- メッセージは言語ごとのカタログから選び、直近の重複をできるだけ避けます。

## 🚀 直接実行

```bash
# メインスクリプト
bash scripts/cheer.sh
CHEERER_LANG=en bash scripts/cheer.sh
CHEERER_LANG=ja CHEERER_VOICE=off bash scripts/cheer.sh
CHEERER_ANIM=fireworks bash scripts/cheer.sh
CHEERER_ANIM=epic bash scripts/cheer.sh
CHEERER_MODE=text bash scripts/cheer.sh
CHEERER_DUMB=true bash scripts/cheer.sh

# ラッパーコマンド
bash bin/cheer --epic
bash bin/cheer --stats
```

`bin/cheer` が現在サポートするフラグは2つだけです：

- `--epic` — バスケットボール + ダンス + 花火を連続再生
- `--stats` — 総トリガー数、到達済みマイルストーン、最後のトリガー時刻を表示

## テスト

```bash
bash tests/run.sh all
bash tests/run.sh state
bash tests/run.sh policy
bash tests/run.sh render
bash tests/run.sh integration
```

## 📁 状態とデータファイル

デフォルトでは cheerer は `${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}` にデータを保存します：

- `stats.json` — 総トリガー数、最後のトリガー時刻、マイルストーン履歴
- `custom-messages.txt` — 任意のカスタム応援文。1行に1件、`#` 行はコメント

クールダウン状態は `/tmp/cheerer_last_trigger_${CLAUDE_SESSION_ID:-default}` に保存されます。

現在のマイルストーン閾値は 10、25、50、100、250、500、1000 回です。マイルストーン到達時はトロフィーメッセージが追加され、花火アニメーションが強制されます。

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
├── bin/
│   └── cheer                # ラッパーコマンド（--epic, --stats）
├── hooks/
│   └── hooks.json           # Hook 設定
├── scripts/
│   ├── cheer.sh             # メインエントリ（Hook ルーティング + 統計）
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
├── README.zh.md
└── README.ja.md
```

## 🔧 カスタマイズ

### 新しいアニメーションを追加する

1. `scripts/animations/` に新しい `.sh` ファイルを作成します
2. `scripts/lib/policy.sh` の `policy_pick_animation` の候補リストに名前を追加します
3. `bash scripts/cheer.sh` または `CHEERER_ANIM=<name> bash scripts/cheer.sh` を実行して動作確認します

### 新しい言語を追加する

1. `scripts/voices/` に `cheer_XX.sh` を作成します
2. `scripts/cheer.sh` に対応する言語処理を追加します
3. `CHEERER_LANG=<code> bash scripts/cheer.sh` を実行して出力を確認します

## 📝 ライセンス

MIT © chinadbo
