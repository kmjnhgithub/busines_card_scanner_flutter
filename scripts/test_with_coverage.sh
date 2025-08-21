#!/bin/bash

# 完整測試腳本（包含覆蓋率報告）
# 使用方式: ./scripts/test_with_coverage.sh

set -e

echo "🔍 開始完整測試流程..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 清理環境
echo -e "${YELLOW}🧹 清理測試環境...${NC}"
flutter clean
flutter pub get

# 2. 程式碼生成（如果需要）
echo -e "${YELLOW}🔧 執行程式碼生成...${NC}"
dart run build_runner build --delete-conflicting-outputs

# 3. 程式碼品質檢查
echo -e "${YELLOW}📋 檢查程式碼品質...${NC}"
dart analyze
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 程式碼品質檢查失敗${NC}"
    exit 1
fi

# 4. 執行測試並生成覆蓋率
echo -e "${YELLOW}🧪 執行測試並生成覆蓋率...${NC}"
flutter test --coverage

# 5. 檢查覆蓋率門檻（可選）
if [ -f coverage/lcov.info ]; then
    # 檢查並安裝 lcov 工具（如果需要）
    if ! command -v lcov &> /dev/null; then
        echo -e "${YELLOW}📦 安裝 lcov 工具...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            brew install lcov
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            sudo apt-get install -y lcov
        else
            echo -e "${RED}⚠️ 請手動安裝 lcov 工具來生成 HTML 報告${NC}"
        fi
    fi
    
    # 計算覆蓋率百分比
    if command -v lcov &> /dev/null; then
        echo -e "${YELLOW}📊 分析覆蓋率...${NC}"
        lcov --list coverage/lcov.info
        
        # 生成 HTML 報告
        echo -e "${YELLOW}🌐 生成 HTML 覆蓋率報告...${NC}"
        genhtml coverage/lcov.info -o coverage/html
        
        # 提供報告連結
        FULL_PATH="$(pwd)/coverage/html/index.html"
        echo -e "${GREEN}📈 覆蓋率報告已生成！${NC}"
        echo -e "${GREEN}   檔案位置: file://$FULL_PATH${NC}"
        echo -e "${GREEN}   在瀏覽器中開啟此連結即可檢視詳細報告${NC}"
        
        # 嘗試自動開啟（僅 macOS）
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}🔍 嘗試自動開啟報告...${NC}"
            open "coverage/html/index.html" 2>/dev/null || true
        fi
    else
        echo -e "${RED}⚠️ lcov 工具安裝失敗，僅能檢視原始 LCOV 檔案: coverage/lcov.info${NC}"
    fi
else
    echo -e "${RED}❌ 未找到覆蓋率檔案: coverage/lcov.info${NC}"
fi

# 6. 成功訊息
echo -e "${GREEN}✅ 測試完成！${NC}"