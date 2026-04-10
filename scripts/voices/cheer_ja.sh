#!/bin/bash
# cheer_ja.sh — 日本語ボイス応援
# 優先度: macOS say → espeak → テキストのみ
# 音声は CHEERER_VOICE 環境変量で制御（on/off/true/false）
# CHEERER_DUMB=true 時は ANSI escape code を出力しない
#
# スタイル：二次元風 + 職場激励（中二テイストあり）

MESSAGES=(
  # 二次元風（1-6）
  "さすがです！神プログラマー降臨！バグを一刀両断！"
  "コミット完了！あなたのコードは伝説になります！"
  "完璧です！テストが全部グリーン、まさに無敵！"
  "このリファクタリング、天才すぎてCIが感動してます！"
  "タスク完了！あなたなら絶対できると思ってました！"
  "すごい！バグを倒すたびに、コードベースが輝きます！"
  # 職場激励（7-10）
  "プルリクエストがマージされました！チームが誇りに思います！"
  "技術的負債がまた減りました、素晴らしい仕事です！"
  "デバッグ完了！あなたのスキルはどんどん上がってますね！"
  "コードレビュー通過！品質へのこだわり、本当に尊敬します！"
  # ボーナス（11-12）
  "また一つTODOが消えた！積み上げてきた実力、見せてくれましたね！"
  "ゼロエラー達成！コンパイラもあなたに感謝してます！"
)

if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
elif [[ -n "${CHEERER_CUSTOM_MSG:-}" ]]; then
  MSG="$CHEERER_CUSTOM_MSG"
else
  MSG="${MESSAGES[$((RANDOM % ${#MESSAGES[@]}))]}"
fi

# テキスト出力（dumb terminal モードでは ANSI なし）
CHEERER_DUMB="${CHEERER_DUMB:-false}"
if [[ "$CHEERER_DUMB" == "true" ]]; then
  echo "🎉 $MSG"
else
  echo -e "\033[1;32m🎉 $MSG\033[0m"
fi

# 音声再生（CHEERER_VOICE で制御、バックグラウンド実行、失敗は無視）
CHEERER_VOICE="${CHEERER_VOICE:-on}"
if [[ "$CHEERER_VOICE" == "off" ]] || [[ "$CHEERER_VOICE" == "false" ]]; then
  exit 0
fi

if command -v say >/dev/null 2>&1; then
  # macOS: バックグラウンド実行、ノンブロッキング（ADR-002）
  say -v "Kyoko" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  # Linux espeak: バックグラウンド実行
  espeak -v ja "$MSG" >/dev/null 2>&1 & disown
fi
# その他のプラットフォーム: テキストのみ（上でechoしてある）

exit 0
