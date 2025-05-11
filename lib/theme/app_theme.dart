import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 核心顏色
  static const Color primaryColor = Color(0xFFFF8A3D); // 橘色主色
  static const Color secondaryColor = Color(0xFFE05D3D); // 暖陶紅副色
  static const Color accentColor = Color(0xFFE76F51); // 暖紅色強調色
  static const Color successColor = Color(0xFF2A9D8F); // 綠松石色成功色
  static const Color warningColor = Color(0xFFE9C46A); // 琥珀色警告色
  static const Color errorColor = Color(0xFFE07A5F); // 橘紅色錯誤色
  static const Color textColor = Color(0xFF3D3D3D); // 深灰色文本
  static const Color textSecondaryColor = Color(0xFF6B6B6B); // 次要文本色
  
  // 亮色主題漸層（米色背景）
  static const List<Color> lightGradient = [
    Color(0xFFF5F1E8), // 淺米色
    Color(0xFFFAF6ED), // 米色
  ];
  
  // 暗色主題漸層
  static const List<Color> darkGradient = [
    Color(0xFF2D2A25), // 深棕色
    Color(0xFF3E3A32), // 暗米色
  ];
  
  // 間距
  static const double spaceXXS = 4.0;
  static const double spaceXS = 8.0;
  static const double spaceSM = 12.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  
  // 圓角
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  
  // 陰影
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  // 亮色主題
  static ThemeData lightTheme = _buildLightTheme();
  
  // 暗色主題
  static ThemeData darkTheme = _buildDarkTheme();
  
  // 建立亮色主題
  static ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9F5EC), // 米色背景
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: const Color(0xFFF9F5EC), // 米色背景
        surface: Colors.white,
        onSurface: textColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF9F5EC), // 米色背景
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansTC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        iconTheme: IconThemeData(
          color: textColor,
          size: 24,
        ),
      ),
      textTheme: Typography.material2018().black.apply(
        fontFamily: 'NotoSansTC',
        bodyColor: textColor,
        displayColor: textColor,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFECE5D6), // 淺米色分隔線
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansTC',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceSM,
            vertical: spaceXS,
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansTC',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: spaceSM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(
            color: Color(0xFFECE5D6), // 淺米色邊框
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(spaceMD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: Color(0xFFECE5D6), // 淺米色邊框
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: Color(0xFFECE5D6), // 淺米色邊框
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1,
          ),
        ),
        hintStyle: TextStyle(
          color: const Color(0xFFBEB9AD), // 淺灰色提示文本
          fontSize: 16,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFF9F5EC), // 米色背景
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFFBEB9AD), // 淺灰色
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor, // 次要文本色
        indicatorColor: primaryColor,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData( // 新增 OutlinedButton 主題
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor, // 文本和圖示顏色
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMD, // 16
            vertical: spaceSM,   // 12 (與 ElevatedButton 一致)
          ),
          side: BorderSide(color: primaryColor, width: 1.5), // 邊框顏色和寬度
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG), // 與 ElevatedButton 一致的圓角 (20)
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansTC',
            fontSize: 16,
            fontWeight: FontWeight.w600, // 與 ElevatedButton 一致的字重
          ),
        ),
      ),
    );
  }
  
  // 建立暗色主題
  static ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF2D2A25), // 深棕色背景
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: const Color(0xFF2D2A25), // 深棕色背景
        surface: const Color(0xFF3E3A32), // 暗米色表面
        onSurface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2D2A25), // 深棕色背景
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansTC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),
      textTheme: Typography.material2018().white.apply(
        fontFamily: 'NotoSansTC',
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF4A453A), // 暗棕色分隔線
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansTC',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceSM,
            vertical: spaceXS,
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansTC',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF3E3A32), // 暗米色表面
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: spaceSM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3E3A32), // 暗米色表面
        contentPadding: const EdgeInsets.all(spaceMD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: Color(0xFF4A453A), // 暗棕色邊框
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: Color(0xFF4A453A), // 暗棕色邊框
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1,
          ),
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF8F8A7E), // 灰棕色提示文本
          fontSize: 16,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2D2A25), // 深棕色背景
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF8F8A7E), // 灰棕色
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey[400],
        indicatorColor: primaryColor,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData( // 新增 OutlinedButton 主題 (暗色)
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor, // 文本和圖示顏色 (在暗色主題中，主色通常仍然可見)
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceSM,
          ),
          side: BorderSide(color: primaryColor.withOpacity(0.7), width: 1.5), // 邊框顏色 (可能需要調整透明度)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansTC',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 