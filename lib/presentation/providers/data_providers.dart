// Re-export repository providers from data layer
export 'package:busines_card_scanner_flutter/data/providers/repository_providers.dart';

// =============================================================================
// Presentation Layer Providers
// =============================================================================
// 這個檔案專門處理 Presentation 層的 Providers
//
// 符合 Clean Architecture 原則：
// - Presentation 層不直接引用 Data 層的具體實作
// - 透過 export 的方式間接使用 Repository Providers
// - 避免跨層直接依賴，維持架構邊界清晰
// =============================================================================

// 注意：原本的 MLKitOCRService 和 IOSVisionOCRService Providers 已移除
// 這些服務現在透過 Data 層的 PlatformOCRService 自動選擇
// 符合 Clean Architecture 的「依賴方向單一」原則
