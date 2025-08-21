#!/bin/bash

# Pre-commit 檢查腳本
# 可連結到 .git/hooks/pre-commit 使用

set -e

echo "🔍 執行 pre-commit 檢查..."

# 只測試被修改的檔案相關的測試
CHANGED_DART_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.dart$' || true)

if [ -z "$CHANGED_DART_FILES" ]; then
    echo "沒有 Dart 檔案變更"
    exit 0
fi

echo "📋 檢查修改的檔案..."
echo "$CHANGED_DART_FILES"

# 1. 格式化檢查（只檢查修改的檔案）
echo "🎨 檢查程式碼格式..."
dart format --set-exit-if-changed $CHANGED_DART_FILES

# 2. 分析檢查
echo "📊 執行靜態分析..."
dart analyze $CHANGED_DART_FILES

# 3. 執行相關測試
echo "🧪 執行相關測試..."
for file in $CHANGED_DART_FILES; do
    # 找出對應的測試檔案
    test_file=$(echo $file | sed 's/lib/test\/unit/' | sed 's/\.dart/_test.dart/')
    if [ -f "$test_file" ]; then
        echo "測試: $test_file"
        flutter test "$test_file"
    fi
done

echo "✅ Pre-commit 檢查通過！"