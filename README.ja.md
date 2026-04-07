# 🎉 cheerer — Claude Code 応援プラグイン

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)


**言語：** [English](README.md) | [中文](README.zh.md) | 日本語


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

### 方法1：Claude Code Plugin（1コマンド — 推奨）⭐

Claude Code が必要です。GitHub から直接インストール — クローン不要：

```bash
claude plugin install github:chinadbo/cheerer
```

Claude Code セッション内から：

```
/plugin install github:chinadbo/cheerer
```

インストール後、自動的に Hook が登録され、すぐに動作します。

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
            "command": "~/.cheerer/scripts/cheer.sh"
          }
        ]
      }
    ]
  }
}
```

## ⚙️ 設定

### 方法1：インタラクティブ設定（Plugin インストール推奨）

プラグインを有効化する際、Claude Code が設定をガイドします：

```
/plugin enable cheerer
> 音声言語（zh / en / ja）: ja
> アニメーション（random / basketball / dance / fireworks）: random
> 音声出力（on / off）: on
```

設定は自動保存され、セッションをまたいで有効です。

### 方法2：環境変数

`~/.bashrc` / `~/.zshrc` または `.claude/settings.json` に設定：

| 変数 | 説明 | 値 | デフォルト |
|------|------|--------|---------|
| `CHEERER_LANG` | 音声言語 | `zh` / `en` / `ja` | `zh` |
| `CHEERER_ANIM` | アニメーション | `basketball` / `dance` / `fireworks` / `random` | `random` |
| `CHEERER_ENABLED` | マスタースイッチ | `true` / `false` | `true` |
| `CHEERER_VOICE` | 音声出力 | `on` / `off` | `on` |
| `CHEERER_COOLDOWN` | トリガー間のクールダウン（秒）| 正の整数 | `3` |

> `CHEERER_*` 環境変数は plugin userConfig より優先されます。

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
