import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';

/// 應用程式主題配置
///
/// 提供淺色和深色主題配置，遵循 Material Design 3 規範
/// 整合自定義的顏色、文字樣式和尺寸系統
/// 確保跨平台的一致性和良好的使用者體驗
class AppTheme {
  AppTheme._();

  // ==================== 淺色主題 ====================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 色彩方案
      colorScheme: _lightColorScheme,

      // 文字主題
      textTheme: _lightTextTheme,

      // 應用程式欄主題
      appBarTheme: _lightAppBarTheme,

      // 卡片主題
      cardTheme: CardThemeData(
        elevation: _lightCardTheme.elevation,
        shadowColor: _lightCardTheme.shadowColor,
        surfaceTintColor: _lightCardTheme.surfaceTintColor,
        color: _lightCardTheme.color,
        shape: _lightCardTheme.shape,
        margin: _lightCardTheme.margin,
      ),

      // 按鈕主題
      elevatedButtonTheme: _lightElevatedButtonTheme,
      textButtonTheme: _lightTextButtonTheme,
      outlinedButtonTheme: _lightOutlinedButtonTheme,

      // 輸入框主題
      inputDecorationTheme: _lightInputDecorationTheme,

      // 底部導航欄主題
      bottomNavigationBarTheme: _lightBottomNavigationBarTheme,

      // 對話框主題
      dialogTheme: DialogThemeData(
        backgroundColor: _lightDialogTheme.backgroundColor,
        surfaceTintColor: _lightDialogTheme.surfaceTintColor,
        shape: _lightDialogTheme.shape,
        titleTextStyle: _lightDialogTheme.titleTextStyle,
        contentTextStyle: _lightDialogTheme.contentTextStyle,
      ),

      // 分隔線主題
      dividerTheme: _lightDividerTheme,

      // 進度指示器主題
      progressIndicatorTheme: _lightProgressIndicatorTheme,

      // 浮動動作按鈕主題
      floatingActionButtonTheme: _lightFloatingActionButtonTheme,

      // 導航欄主題
      navigationBarTheme: _lightNavigationBarTheme,

      // 擴展主題配置
      extensions: const [],

      // 其他設定
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.cardBackground,
      primaryColor: AppColors.primary,
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.highlight,
      focusColor: AppColors.primary.withValues(alpha: 0.2),
      hoverColor: AppColors.primary.withValues(alpha: 0.1),

      // 視覺密度 - 適用於不同平台
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ==================== 深色主題 ====================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // 色彩方案
      colorScheme: _darkColorScheme,

      // 文字主題
      textTheme: _darkTextTheme,

      // 應用程式欄主題
      appBarTheme: _darkAppBarTheme,

      // 卡片主題
      cardTheme: CardThemeData(
        elevation: _darkCardTheme.elevation,
        shadowColor: _darkCardTheme.shadowColor,
        surfaceTintColor: _darkCardTheme.surfaceTintColor,
        color: _darkCardTheme.color,
        shape: _darkCardTheme.shape,
        margin: _darkCardTheme.margin,
      ),

      // 按鈕主題
      elevatedButtonTheme: _darkElevatedButtonTheme,
      textButtonTheme: _darkTextButtonTheme,
      outlinedButtonTheme: _darkOutlinedButtonTheme,

      // 輸入框主題
      inputDecorationTheme: _darkInputDecorationTheme,

      // 底部導航欄主題
      bottomNavigationBarTheme: _darkBottomNavigationBarTheme,

      // 對話框主題
      dialogTheme: DialogThemeData(
        backgroundColor: _darkDialogTheme.backgroundColor,
        surfaceTintColor: _darkDialogTheme.surfaceTintColor,
        shape: _darkDialogTheme.shape,
        titleTextStyle: _darkDialogTheme.titleTextStyle,
        contentTextStyle: _darkDialogTheme.contentTextStyle,
      ),

      // 分隔線主題
      dividerTheme: _darkDividerTheme,

      // 進度指示器主題
      progressIndicatorTheme: _darkProgressIndicatorTheme,

      // 浮動動作按鈕主題
      floatingActionButtonTheme: _darkFloatingActionButtonTheme,

      // 導航欄主題
      navigationBarTheme: _darkNavigationBarTheme,

      // 擴展主題配置
      extensions: const [],

      // 其他設定
      scaffoldBackgroundColor: AppColors.backgroundDark,
      canvasColor: AppColors.cardBackgroundDark,
      primaryColor: AppColors.primary,
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.highlightDark,
      focusColor: AppColors.primary.withValues(alpha: 0.2),
      hoverColor: AppColors.primary.withValues(alpha: 0.1),

      // 視覺密度
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ==================== 淺色主題色彩方案 ====================

  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryVariant,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryVariant,
    surface: AppColors.surface,
    background: AppColors.background,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.primaryText,
    onBackground: AppColors.primaryText,
    onError: Colors.white,
    brightness: Brightness.light,
  );

  // ==================== 深色主題色彩方案 ====================

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryVariant,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryVariant,
    surface: AppColors.surfaceDark,
    background: AppColors.backgroundDark,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.primaryTextDark,
    onBackground: AppColors.primaryTextDark,
    onError: Colors.white,
    brightness: Brightness.dark,
  );

  // ==================== 文字主題 ====================

  static TextTheme get _lightTextTheme {
    return TextTheme(
      displayLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.display,
        Brightness.light,
      ),
      displayMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.gigantic,
        Brightness.light,
      ),
      displaySmall: AppTextStyles.adaptToTheme(
        AppTextStyles.headline1,
        Brightness.light,
      ),
      headlineLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.headline1,
        Brightness.light,
      ),
      headlineMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.headline2,
        Brightness.light,
      ),
      headlineSmall: AppTextStyles.adaptToTheme(
        AppTextStyles.headline3,
        Brightness.light,
      ),
      titleLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.headline4,
        Brightness.light,
      ),
      titleMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.headline5,
        Brightness.light,
      ),
      titleSmall: AppTextStyles.adaptToTheme(
        AppTextStyles.headline6,
        Brightness.light,
      ),
      bodyLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.bodyLarge,
        Brightness.light,
      ),
      bodyMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.bodyMedium,
        Brightness.light,
      ),
      bodySmall: AppTextStyles.adaptToTheme(
        AppTextStyles.bodySmall,
        Brightness.light,
      ),
      labelLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.labelLarge,
        Brightness.light,
      ),
      labelMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.labelMedium,
        Brightness.light,
      ),
      labelSmall: AppTextStyles.adaptToTheme(
        AppTextStyles.labelSmall,
        Brightness.light,
      ),
    );
  }

  static TextTheme get _darkTextTheme {
    return TextTheme(
      displayLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.display,
        Brightness.dark,
      ),
      displayMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.gigantic,
        Brightness.dark,
      ),
      displaySmall: AppTextStyles.adaptToTheme(
        AppTextStyles.headline1,
        Brightness.dark,
      ),
      headlineLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.headline1,
        Brightness.dark,
      ),
      headlineMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.headline2,
        Brightness.dark,
      ),
      headlineSmall: AppTextStyles.adaptToTheme(
        AppTextStyles.headline3,
        Brightness.dark,
      ),
      titleLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.headline4,
        Brightness.dark,
      ),
      titleMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.headline5,
        Brightness.dark,
      ),
      titleSmall: AppTextStyles.adaptToTheme(
        AppTextStyles.headline6,
        Brightness.dark,
      ),
      bodyLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.bodyLarge,
        Brightness.dark,
      ),
      bodyMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.bodyMedium,
        Brightness.dark,
      ),
      bodySmall: AppTextStyles.adaptToTheme(
        AppTextStyles.bodySmall,
        Brightness.dark,
      ),
      labelLarge: AppTextStyles.adaptToTheme(
        AppTextStyles.labelLarge,
        Brightness.dark,
      ),
      labelMedium: AppTextStyles.adaptToTheme(
        AppTextStyles.labelMedium,
        Brightness.dark,
      ),
      labelSmall: AppTextStyles.adaptToTheme(
        AppTextStyles.labelSmall,
        Brightness.dark,
      ),
    );
  }

  // ==================== 應用程式欄主題 ====================

  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    elevation: 0,
    backgroundColor: AppColors.cardBackground,
    foregroundColor: AppColors.primaryText,
    titleTextStyle: AppTextStyles.headline5,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    iconTheme: IconThemeData(
      color: AppColors.primaryText,
      size: AppDimensions.iconMedium,
    ),
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: 0,
    backgroundColor: AppColors.cardBackgroundDark,
    foregroundColor: AppColors.primaryTextDark,
    titleTextStyle: AppTextStyles.headline5,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    iconTheme: IconThemeData(
      color: AppColors.primaryTextDark,
      size: AppDimensions.iconMedium,
    ),
  );

  // ==================== 卡片主題 ====================

  static CardTheme get _lightCardTheme {
    return CardTheme(
      elevation: 2,
      shadowColor: AppColors.shadow,
      surfaceTintColor: AppColors.cardBackground,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      margin: AppDimensions.marginCard,
    );
  }

  static CardTheme get _darkCardTheme {
    return CardTheme(
      elevation: 2,
      shadowColor: AppColors.shadowDark,
      surfaceTintColor: AppColors.cardBackgroundDark,
      color: AppColors.cardBackgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      margin: AppDimensions.marginCard,
    );
  }

  // ==================== 按鈕主題 ====================

  static ElevatedButtonThemeData get _lightElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.disabledText,
        disabledBackgroundColor: AppColors.border,
        elevation: 2,
        shadowColor: AppColors.shadow,
        padding: AppDimensions.paddingButton,
        minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTextStyles.primaryButton,
      ),
    );
  }

  static ElevatedButtonThemeData get _darkElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.disabledTextDark,
        disabledBackgroundColor: AppColors.borderDark,
        elevation: 2,
        shadowColor: AppColors.shadowDark,
        padding: AppDimensions.paddingButton,
        minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTextStyles.primaryButton,
      ),
    );
  }

  static TextButtonThemeData get _lightTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.disabledText,
        padding: AppDimensions.paddingButton,
        minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTextStyles.textButton,
      ),
    );
  }

  static TextButtonThemeData get _darkTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.disabledTextDark,
        padding: AppDimensions.paddingButton,
        minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTextStyles.textButton,
      ),
    );
  }

  static OutlinedButtonThemeData get _lightOutlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.disabledText,
        side: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.borderMedium,
        ),
        padding: AppDimensions.paddingButton,
        minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTextStyles.secondaryButton,
      ),
    );
  }

  static OutlinedButtonThemeData get _darkOutlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.disabledTextDark,
        side: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.borderMedium,
        ),
        padding: AppDimensions.paddingButton,
        minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTextStyles.secondaryButton,
      ),
    );
  }

  // ==================== 輸入框主題 ====================

  static InputDecorationTheme get _lightInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: AppDimensions.paddingTextField,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.focusBorder,
          width: AppDimensions.borderFocus,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.borderFocus,
        ),
      ),
      labelStyle: AppTextStyles.subtitle2,
      hintStyle: AppTextStyles.hint,
      errorStyle: AppTextStyles.error,
    );
  }

  static InputDecorationTheme get _darkInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBackgroundDark,
      contentPadding: AppDimensions.paddingTextField,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.focusBorder,
          width: AppDimensions.borderFocus,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.borderFocus,
        ),
      ),
      labelStyle: AppTextStyles.adaptToTheme(
        AppTextStyles.subtitle2,
        Brightness.dark,
      ),
      hintStyle: AppTextStyles.adaptToTheme(
        AppTextStyles.hint,
        Brightness.dark,
      ),
      errorStyle: AppTextStyles.error,
    );
  }

  // ==================== 其他元件主題 ====================

  static const BottomNavigationBarThemeData _lightBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  static const BottomNavigationBarThemeData _darkBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryTextDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  static DialogTheme get _lightDialogTheme {
    return DialogTheme(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      titleTextStyle: AppTextStyles.headline4,
      contentTextStyle: AppTextStyles.bodyMedium,
    );
  }

  static DialogTheme get _darkDialogTheme {
    return DialogTheme(
      backgroundColor: AppColors.cardBackgroundDark,
      surfaceTintColor: AppColors.cardBackgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      titleTextStyle: AppTextStyles.adaptToTheme(
        AppTextStyles.headline4,
        Brightness.dark,
      ),
      contentTextStyle: AppTextStyles.adaptToTheme(
        AppTextStyles.bodyMedium,
        Brightness.dark,
      ),
    );
  }

  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.separator,
    thickness: AppDimensions.separatorHeight,
    space: AppDimensions.separatorHeight,
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.separatorDark,
    thickness: AppDimensions.separatorHeight,
    space: AppDimensions.separatorHeight,
  );

  static const ProgressIndicatorThemeData _lightProgressIndicatorTheme =
      ProgressIndicatorThemeData(color: AppColors.primary);

  static const ProgressIndicatorThemeData _darkProgressIndicatorTheme =
      ProgressIndicatorThemeData(color: AppColors.primary);

  static const FloatingActionButtonThemeData _lightFloatingActionButtonTheme =
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
      );

  static const FloatingActionButtonThemeData _darkFloatingActionButtonTheme =
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
      );

  static NavigationBarThemeData get _lightNavigationBarTheme {
    return NavigationBarThemeData(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: AppColors.cardBackground,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppTextStyles.withColor(
            AppTextStyles.labelSmall,
            AppColors.primary,
          );
        }
        return AppTextStyles.withColor(
          AppTextStyles.labelSmall,
          AppColors.secondaryText,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.secondaryText);
      }),
    );
  }

  static NavigationBarThemeData get _darkNavigationBarTheme {
    return NavigationBarThemeData(
      backgroundColor: AppColors.cardBackgroundDark,
      surfaceTintColor: AppColors.cardBackgroundDark,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppTextStyles.withColor(
            AppTextStyles.labelSmall,
            AppColors.primary,
          );
        }
        return AppTextStyles.withColor(
          AppTextStyles.labelSmall,
          AppColors.secondaryTextDark,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.secondaryTextDark);
      }),
    );
  }

  // ==================== 系統覆蓋樣式 ====================
  // 注意：System overlay styles 已移動到各個具體使用的地方，避免未使用的全域定義
}
