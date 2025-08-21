#!/bin/bash

# 分層測試腳本 - 按 Clean Architecture 層級執行測試
# 使用方式: ./scripts/test_by_layer.sh [domain|data|presentation|all]

set -e

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 預設測試所有層
LAYER=${1:-all}

run_domain_tests() {
    echo -e "${BLUE}🏛️ 測試 Domain 層...${NC}"
    flutter test test/unit/domain/
}

run_data_tests() {
    echo -e "${BLUE}💾 測試 Data 層...${NC}"
    flutter test test/unit/data/
}

run_presentation_tests() {
    echo -e "${BLUE}🖼️ 測試 Presentation 層...${NC}"
    flutter test test/unit/presentation/
}

run_architecture_tests() {
    echo -e "${BLUE}🏗️ 測試架構邊界...${NC}"
    if [ -f test/architecture/architecture_test.dart ]; then
        flutter test test/architecture/architecture_test.dart
    else
        echo "未找到架構測試檔案"
    fi
}

case $LAYER in
    domain)
        run_domain_tests
        ;;
    data)
        run_data_tests
        ;;
    presentation)
        run_presentation_tests
        ;;
    architecture)
        run_architecture_tests
        ;;
    all)
        echo -e "${BLUE}🔍 執行所有層級測試...${NC}"
        run_domain_tests
        run_data_tests
        run_presentation_tests
        run_architecture_tests
        ;;
    *)
        echo "使用方式: $0 [domain|data|presentation|architecture|all]"
        exit 1
        ;;
esac

echo -e "${GREEN}✅ $LAYER 層測試完成！${NC}"