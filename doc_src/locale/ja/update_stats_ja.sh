#!/usr/bin/env bash

# --- 設定項目 ---
# あなたのGitHubリポジトリのURLに合わせて変更してください
REPO_URL="https://t4k44.github.io/fish-shell-ja"
LOCALE_DIR="doc_src/locale/ja/LC_MESSAGES"
OUTPUT_FILE="doc_src/locale/ja/README.md"
# ----------------

{
    echo "# 日本語翻訳進捗状況"
    echo "※ \`msgfmt --statistics\` を使用して自動生成しています。"
    echo ""
    echo "最終更新: $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "| 状態 | ファイル名 | 進捗率 | 翻訳済 | 未翻訳 | 曖昧 |"
    echo "| :---: | :--- | :---: | :---: | :---: | :---: |"
} > "$OUTPUT_FILE"

find "$LOCALE_DIR" -name "*.po" | sort | while read -r file; do
    # 統計情報の取得
    stats=$(LC_ALL=C msgfmt --statistics -o /dev/null "$file" 2>&1)

    trans=$(echo "$stats" | grep -oP '\d+(?= translated)' || echo 0)
    fuzzy=$(echo "$stats" | grep -oP '\d+(?= fuzzy)' || echo 0)
    untrans=$(echo "$stats" | grep -oP '\d+(?= untranslated)' || echo 0)

    # 進捗計算
    total=$((trans + fuzzy + untrans))
    percent=0
    if [ "$total" -gt 0 ]; then
        percent=$((trans * 100 / total))
    fi

    # アイコンの判定
    if [ "$percent" -eq 100 ]; then
        status="✅" # 完了
    elif [ "$percent" -gt 0 ] || [ "$fuzzy" -gt 0 ]; then
        status="🚧" # 作業中
    else
        status="💤" # 未着手
    fi

    # ファイル名とGitHubリンクの作成
    rel_path=${file#$LOCALE_DIR/}
    file_link="[${rel_path%.po}]($REPO_URL/${rel_path%.po}.html)"

    echo "| $status | $file_link | ${percent}% | $trans | $untrans | $fuzzy |" >> "$OUTPUT_FILE"
done

{
    echo ""
    echo "## アイコンの説明"
    echo "- ✅: 翻訳完了 (100%)"
    echo "- 🚧: 翻訳作業中 / 要確認 (fuzzyあり)"
    echo "- 💤: 未着手"
    echo ""
    echo "## build"
    echo "\`REPO_ROOT/doc_src/locale/ja/build_ja.sh\` を使用してドキュメントの生成をしています。"
} >> "$OUTPUT_FILE"
