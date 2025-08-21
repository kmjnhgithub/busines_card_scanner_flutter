#!/bin/bash

# CI/CD 環境測試腳本
# 使用方式: ./scripts/ci_test.sh

set -e

# 錯誤處理
trap 'echo "❌ 測試失敗於第 $LINENO 行"' ERR

# 環境變數
export CI=true
export FLUTTER_TEST_REPORTER=github

echo "🚀 CI/CD 測試開始..."
echo "Flutter 版本: $(flutter --version --machine | grep '"flutterVersion"' | cut -d'"' -f4)"

# 1. 依賴安裝
echo "📦 安裝依賴..."
flutter pub get

# 2. 程式碼生成
echo "🔧 程式碼生成..."
dart run build_runner build --delete-conflicting-outputs

# 3. 程式碼品質
echo "📋 程式碼品質檢查..."
dart analyze --fatal-infos --fatal-warnings

# 4. 格式檢查
echo "🎨 格式檢查..."
dart format --set-exit-if-changed lib test

# 5. 單元測試（輸出 JSON 格式供 CI 解析）
echo "🧪 執行單元測試..."
flutter test --coverage --machine > test-results.json

# 6. 架構測試
echo "🏗️ 架構邊界測試..."
if [ -f test/architecture/architecture_test.dart ]; then
    flutter test test/architecture/architecture_test.dart
fi

# 7. 覆蓋率報告（如果有 codecov token）
if [ ! -z "$CODECOV_TOKEN" ]; then
    echo "📊 上傳覆蓋率報告..."
    bash <(curl -s https://codecov.io/bash)
fi

# 8. 生成測試摘要
echo "📝 生成測試摘要..."
total_tests=$(grep -o '"test"' test-results.json | wc -l)
echo "總測試數: $total_tests"

echo "✅ CI/CD 測試完成！"