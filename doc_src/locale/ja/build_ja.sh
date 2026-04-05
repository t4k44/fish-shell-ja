#!/usr/bin/env bash
# @describe 日本語訳ビルド
# @meta     version       v0.1.0

# @cmd
main() {
    local modified_files
    modified_files=$(jj log -r @ -T 'diff.files().map(|e| e.path()).join(" ")' --no-graph)

    if [ -n "$modified_files" ]; then
        echo "[main] Files found: $modified_files"
        replace $modified_files
    else
        echo "[main] No changes detected in @."
    fi

    echo "[main] Running sphinx-build..."

    uv run sphinx-build -b html -D language=ja -D locale_dirs=locale doc_src _build/html/ja
    doc_src/locale/ja/update_stats_ja.sh
}

# @cmd
# @arg      target_files+ sed置換対象ファイル名
replace() {
    # argc経由の引数、または直接の引数からファイルリストを作成
    local files=("${argc_target_files[@]:-$@}")

    if [ ${#files[@]} -eq 0 ]; then
        echo "[replace] Error: No files specified for replacement."
        return 1
    fi

    echo "[replace] Starting sed processing for ${#files[@]} files..."

    for file in "${files[@]}"
    do
            # -e 's/\([^*`]\)\s\?（\s\?/\1(/g' \
            # -e 's/\s\?）\s\?\([^*]\)/)\1/g' \
            # -e 's/\([^a-z.*`)]\)\s\?(\s\?/\1(/g' \
            # -e 's/\s\/)\s\?\([^a-zA-Z.*`(]\?\)/)\1/g' \
            # -e 's/ ) /)/g' \
        sed -i $file \
            -e 's/（/(/g' \
            -e 's/）/)/g' \
            -e 's/：/: /g' \
            -e 's/長いフラグ/ロングフラグ/g' \
            -e 's/ または / 、 /g' \
            -e 's/注: /Note: /g' \
            -e 's/FIRST AUTHOR <EMAIL@ADDRESS>/t4k44 <95964+t4k44@users.noreply.github.com>/' \
            -e "s/YEAR-MO-DA HO:MI+ZONE/$(date +'%F %R+0900')/" \
            -e "s/PO-Revision-Date: .*+0900/PO-Revision-Date: $(date +'%F %R+0900')/" \
            -e 's/FULL NAME <EMAIL@ADDRESS>/t4k44 <95964+t4k44@users.noreply.github.com>/'
    done
    # jj diff ${argc_target_files[@]}
}

# @cmd masterを更新し、ブランチを更新
merge_branch() {
  jj git fetch --remote upstream --bookmark master
  cid=$(jj log -r 'master@upstream' --no-graph -T 'commit_id')
  jj new @ $cid -m "merge: update from upstream master"
  if jj st | grep -q "conflict"; then
      echo "コンフリクトが発生しました。手動で解決してください。"
      return 1
  fi
  update_po
  jj bookmark set doc-translation -r @
}

# @cmd poファイル更新処理
update_po() {
  # cp -f ./CONTRIBUTING.rst doc_src/contributing.rst
  # cp -f ./CHANGELOG.rst doc_src/relnotes.rst

  uv run sphinx-build -b gettext doc_src _build/locale
  uv run sphinx-intl update -p _build/locale -l ja --locale-dir doc_src/locale --jobs 1

  # git checkout doc_src/contributing.rst doc_src/relnotes.rst
}

eval "$(argc --argc-eval "$0" "$@")"
