#!/bin/bash

# 基礎測試腳本
# 使用方式: ./scripts/test.sh

set -e  # 遇到錯誤立即停止

echo "🔍 開始執行測試套件..."

# 1. 程式碼品質檢查
echo "📋 檢查程式碼品質..."
dart analyze
if [ $? -ne 0 ]; then
    echo "❌ 程式碼品質檢查失敗"
    exit 1
fi

# 2. 格式化檢查
echo "🎨 檢查程式碼格式..."
dart format --set-exit-if-changed lib test
if [ $? -ne 0 ]; then
    echo "❌ 程式碼格式不正確，請執行 'dart format lib test'"
    exit 1
fi

# 3. 執行單元測試
echo "🧪 執行單元測試..."
flutter test --no-coverage

# 4. 成功訊息
echo "✅ 所有測試通過！"