#!/bin/bash

# 覆蓋率報告檢視腳本
# 使用方式: ./scripts/view_coverage.sh

set -e

echo "📊 覆蓋率報告檢視工具"

# 檢查覆蓋率檔案是否存在
if [ ! -f coverage/lcov.info ]; then
    echo "❌ 未找到覆蓋率檔案，請先執行: ./scripts/test_with_coverage.sh"
    exit 1
fi

# 顯示覆蓋率統計
echo "📈 目前覆蓋率統計:"
lcov --list coverage/lcov.info

echo ""
echo "🎯 重點覆蓋率資訊:"

# 顯示我們新增 UseCase 的覆蓋率
echo "新增的 UseCase 覆蓋率:"
lcov --list coverage/lcov.info | grep "manage_api_key_usecase\|validate_ai_service_usecase"

echo ""
echo "API Key Repository 覆蓋率:"
lcov --list coverage/lcov.info | grep "api_key_repository_impl"

# 檢查 HTML 報告
if [ -d coverage/html ]; then
    echo ""
    echo "🌐 HTML 報告可用:"
    FULL_PATH="$(pwd)/coverage/html/index.html"
    echo "   檔案位置: file://$FULL_PATH"
    
    # macOS 自動開啟
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🔍 是否要開啟 HTML 報告? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            open "coverage/html/index.html"
        fi
    fi
else
    echo ""
    echo "⚠️ HTML 報告不存在，正在生成..."
    genhtml coverage/lcov.info -o coverage/html
    echo "✅ HTML 報告已生成: coverage/html/index.html"
fi