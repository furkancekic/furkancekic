import 'package:flutter/material.dart';
import 'dart:ui';
import 'theme_provider.dart';
import 'theme_styles.dart';

class AppTheme {
  // Renk paleti tanımları
  static const Map<ColorPalette, ThemeColors> _themeColors = {
    // Mavi paleti (mevcut varsayılan)
    ColorPalette.blue: ThemeColors(
      primaryColor: Color(0xFF0D47A1),
      accentColor: Color(0xFF00E5FF),
      positiveColor: Color(0xFF00E676),
      negativeColor: Color(0xFFFF1744),
      warningColor: Color(0xFFFFD600),
    ),

    // Mor paleti
    ColorPalette.purple: ThemeColors(
      primaryColor: Color(0xFF6200EA),
      accentColor: Color(0xFFBA68C8),
      positiveColor: Color(0xFF00E676),
      negativeColor: Color(0xFFFF1744),
      warningColor: Color(0xFFFFD600),
    ),

    // Yeşil paleti
    ColorPalette.green: ThemeColors(
      primaryColor: Color(0xFF2E7D32),
      accentColor: Color(0xFF69F0AE),
      positiveColor: Color(0xFF00E676),
      negativeColor: Color(0xFFFF1744),
      warningColor: Color(0xFFFFD600),
    ),

    // Turuncu paleti
    ColorPalette.orange: ThemeColors(
      primaryColor: Color(0xFFE65100),
      accentColor: Color(0xFFFFAB40),
      positiveColor: Color(0xFF00E676),
      negativeColor: Color(0xFFFF1744),
      warningColor: Color(0xFFFFD600),
    ),

    // Kırmızı paleti
    ColorPalette.red: ThemeColors(
      primaryColor: Color(0xFFB71C1C),
      accentColor: Color(0xFFFF5252),
      positiveColor: Color(0xFF00E676),
      negativeColor: Color(0xFFFF1744),
      warningColor: Color(0xFFFFD600),
    ),
  };

  // Modern tema için renkler
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _darkCardColor = Color(0xFF1E1E1E);
  static const Color _darkCardColorLight = Color(0xFF2A2A2A);

  static const Color _lightBackgroundColor = Color(0xFFFAFAFA);
  static const Color _lightCardColor = Color(0xFFFFFFFF);
  static const Color _lightCardColorLight = Color(0xFFF5F5F5);

  // Glassmorphism tema için renkler
  static const Color _glassDarkBackgroundColor = Color(0xFF0A0E27);
  static const Color _glassDarkCardColor = Color.fromRGBO(255, 255, 255, 0.05);
  static const Color _glassDarkCardColorLight =
      Color.fromRGBO(255, 255, 255, 0.08);

  static const Color _glassLightBackgroundColor = Color(0xFFF0F4F8);
  static const Color _glassLightCardColor = Color.fromRGBO(255, 255, 255, 0.7);
  static const Color _glassLightCardColorLight =
      Color.fromRGBO(255, 255, 255, 0.85);

  // Tema modları için metin renkleri
  static const Color _darkTextPrimary = Colors.white;
  static const Color _darkTextSecondary = Color(0xFFB0B0B0);

  static const Color _lightTextPrimary = Color(0xFF1A1A1A);
  static const Color _lightTextSecondary = Color(0xFF606060);

  // Statik erişimler için mevcut renkler (geriye dönük uyumluluk için)
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF00E5FF);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color cardColorLight = Color(0xFF2A2A2A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color positiveColor = Color(0xFF00E676);
  static const Color negativeColor = Color(0xFFFF1744);
  static const Color warningColor = Color(0xFFFFD600);

  static const List<Color> primaryGradient = [
    Color(0xFF0D47A1),
    Color(0xFF00E5FF),
  ];

  // Karanlık tema oluştur (varsayılan tema - geriye dönük uyumluluk)
  static ThemeData get darkTheme {
    return getDarkTheme(ColorPalette.blue, ThemeStyle.modern);
  }

  // Karanlık tema oluştur (stil ve paletle birlikte)
  static ThemeData getDarkTheme(ColorPalette palette, ThemeStyle style) {
    final colors = _themeColors[palette]!;

    if (style == ThemeStyle.glassmorphism) {
      return _createGlassmorphismDarkTheme(colors);
    } else {
      return _createModernDarkTheme(colors);
    }
  }

  // Aydınlık tema oluştur
  static ThemeData getLightTheme(ColorPalette palette, ThemeStyle style) {
    final colors = _themeColors[palette]!;

    if (style == ThemeStyle.glassmorphism) {
      return _createGlassmorphismLightTheme(colors);
    } else {
      return _createModernLightTheme(colors);
    }
  }

  // Modern Dark Theme
  static ThemeData _createModernDarkTheme(ThemeColors colors) {
    final List<Color> gradientColors = [
      colors.primaryColor,
      colors.accentColor,
    ];

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: _darkBackgroundColor,
      primaryColor: colors.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: colors.primaryColor,
        secondary: colors.accentColor,
        background: _darkBackgroundColor,
        surface: _darkCardColor,
      ),
      cardTheme: CardTheme(
        color: _darkCardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.accentColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge:
            TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: _darkTextPrimary),
        titleSmall: TextStyle(color: _darkTextSecondary),
        bodyLarge: TextStyle(color: _darkTextPrimary),
        bodyMedium: TextStyle(color: _darkTextPrimary),
        bodySmall: TextStyle(color: _darkTextSecondary),
        labelLarge:
            TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: _darkTextPrimary,
          backgroundColor: colors.primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkCardColor,
        selectedItemColor: colors.accentColor,
        unselectedItemColor: _darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        hintStyle: const TextStyle(color: _darkTextSecondary),
      ),
      extensions: [
        AppThemeExtension(
          primaryColor: colors.primaryColor,
          accentColor: colors.accentColor,
          positiveColor: colors.positiveColor,
          negativeColor: colors.negativeColor,
          warningColor: colors.warningColor,
          cardColor: _darkCardColor,
          cardColorLight: _darkCardColorLight,
          textPrimary: _darkTextPrimary,
          textSecondary: _darkTextSecondary,
          gradientColors: gradientColors,
          isDark: true,
          themeStyle: ThemeStyle.modern,
          gradientBackgroundColors: [
            _darkBackgroundColor,
            const Color(0xFF192138),
          ],
        ),
      ],
    );
  }

  // Modern Light Theme - Daha kullanıcı dostu
  static ThemeData _createModernLightTheme(ThemeColors colors) {
    final List<Color> gradientColors = [
      colors.primaryColor,
      colors.accentColor,
    ];

    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: _lightBackgroundColor,
      primaryColor: colors.primaryColor,
      colorScheme: ColorScheme.light(
        primary: colors.primaryColor,
        secondary: colors.accentColor,
        background: _lightBackgroundColor,
        surface: _lightCardColor,
      ),
      cardTheme: CardTheme(
        color: _lightCardColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.primaryColor),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge:
            TextStyle(color: _lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: _lightTextPrimary),
        titleSmall: TextStyle(color: _lightTextSecondary),
        bodyLarge: TextStyle(color: _lightTextPrimary),
        bodyMedium: TextStyle(color: _lightTextPrimary),
        bodySmall: TextStyle(color: _lightTextSecondary),
        labelLarge:
            TextStyle(color: _lightTextPrimary, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: colors.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightCardColor,
        selectedItemColor: colors.primaryColor,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightCardColorLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        hintStyle: TextStyle(color: _lightTextSecondary),
      ),
      extensions: [
        AppThemeExtension(
          primaryColor: colors.primaryColor,
          accentColor: colors.accentColor,
          positiveColor: colors.positiveColor,
          negativeColor: colors.negativeColor,
          warningColor: colors.warningColor,
          cardColor: _lightCardColor,
          cardColorLight: _lightCardColorLight,
          textPrimary: _lightTextPrimary,
          textSecondary: _lightTextSecondary,
          gradientColors: gradientColors,
          isDark: false,
          themeStyle: ThemeStyle.modern,
          gradientBackgroundColors: [
            _lightBackgroundColor,
            _lightBackgroundColor,
          ],
        ),
      ],
    );
  }

  // Glassmorphism Dark Theme
  static ThemeData _createGlassmorphismDarkTheme(ThemeColors colors) {
    final List<Color> gradientColors = [
      colors.primaryColor,
      colors.accentColor,
    ];

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: _glassDarkBackgroundColor,
      primaryColor: colors.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: colors.primaryColor,
        secondary: colors.accentColor,
        background: _glassDarkBackgroundColor,
        surface: _glassDarkCardColor,
      ),
      cardTheme: CardTheme(
        color: _glassDarkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.accentColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge:
            TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: _darkTextPrimary),
        titleSmall: TextStyle(color: _darkTextSecondary),
        bodyLarge: TextStyle(color: _darkTextPrimary),
        bodyMedium: TextStyle(color: _darkTextPrimary),
        bodySmall: TextStyle(color: _darkTextSecondary),
        labelLarge:
            TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: _darkTextPrimary,
          backgroundColor: colors.primaryColor.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _glassDarkCardColor,
        selectedItemColor: colors.accentColor,
        unselectedItemColor: _darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _glassDarkCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        hintStyle: const TextStyle(color: _darkTextSecondary),
      ),
      extensions: [
        AppThemeExtension(
          primaryColor: colors.primaryColor,
          accentColor: colors.accentColor,
          positiveColor: colors.positiveColor,
          negativeColor: colors.negativeColor,
          warningColor: colors.warningColor,
          cardColor: _glassDarkCardColor,
          cardColorLight: _glassDarkCardColorLight,
          textPrimary: _darkTextPrimary,
          textSecondary: _darkTextSecondary,
          gradientColors: gradientColors,
          isDark: true,
          themeStyle: ThemeStyle.glassmorphism,
          gradientBackgroundColors: [
            _glassDarkBackgroundColor,
            const Color(0xFF151C3D),
          ],
        ),
      ],
    );
  }

  // Glassmorphism Light Theme
  static ThemeData _createGlassmorphismLightTheme(ThemeColors colors) {
    final List<Color> gradientColors = [
      colors.primaryColor,
      colors.accentColor,
    ];

    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: _glassLightBackgroundColor,
      primaryColor: colors.primaryColor,
      colorScheme: ColorScheme.light(
        primary: colors.primaryColor,
        secondary: colors.accentColor,
        background: _glassLightBackgroundColor,
        surface: _glassLightCardColor,
      ),
      cardTheme: CardTheme(
        color: _glassLightCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.primaryColor),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge:
            TextStyle(color: _lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: _lightTextPrimary),
        titleSmall: TextStyle(color: _lightTextSecondary),
        bodyLarge: TextStyle(color: _lightTextPrimary),
        bodyMedium: TextStyle(color: _lightTextPrimary),
        bodySmall: TextStyle(color: _lightTextSecondary),
        labelLarge:
            TextStyle(color: _lightTextPrimary, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: colors.primaryColor.withOpacity(0.9),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _glassLightCardColor,
        selectedItemColor: colors.primaryColor,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black12, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black12, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        hintStyle: TextStyle(color: _lightTextSecondary),
      ),
      extensions: [
        AppThemeExtension(
          primaryColor: colors.primaryColor,
          accentColor: colors.accentColor,
          positiveColor: colors.positiveColor,
          negativeColor: colors.negativeColor,
          warningColor: colors.warningColor,
          cardColor: _glassLightCardColor,
          cardColorLight: _glassLightCardColorLight,
          textPrimary: _lightTextPrimary,
          textSecondary: _lightTextSecondary,
          gradientColors: gradientColors,
          isDark: false,
          themeStyle: ThemeStyle.glassmorphism,
          gradientBackgroundColors: [
            _glassLightBackgroundColor,
            const Color(0xFFE3E9F0),
          ],
        ),
      ],
    );
  }
}

// Farklı renk paletleri için sınıf
class ThemeColors {
  final Color primaryColor;
  final Color accentColor;
  final Color positiveColor;
  final Color negativeColor;
  final Color warningColor;

  const ThemeColors({
    required this.primaryColor,
    required this.accentColor,
    required this.positiveColor,
    required this.negativeColor,
    required this.warningColor,
  });
}

// ThemeExtension ile temaları widgets'larda kolay erişim için
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color primaryColor;
  final Color accentColor;
  final Color positiveColor;
  final Color negativeColor;
  final Color warningColor;
  final Color cardColor;
  final Color cardColorLight;
  final Color textPrimary;
  final Color textSecondary;
  final List<Color> gradientColors;
  final bool isDark;
  final ThemeStyle themeStyle;
  final List<Color> gradientBackgroundColors;

  AppThemeExtension({
    required this.primaryColor,
    required this.accentColor,
    required this.positiveColor,
    required this.negativeColor,
    required this.warningColor,
    required this.cardColor,
    required this.cardColorLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.gradientColors,
    required this.isDark,
    required this.themeStyle,
    required this.gradientBackgroundColors,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? positiveColor,
    Color? negativeColor,
    Color? warningColor,
    Color? cardColor,
    Color? cardColorLight,
    Color? textPrimary,
    Color? textSecondary,
    List<Color>? gradientColors,
    bool? isDark,
    ThemeStyle? themeStyle,
    List<Color>? gradientBackgroundColors,
  }) {
    return AppThemeExtension(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      positiveColor: positiveColor ?? this.positiveColor,
      negativeColor: negativeColor ?? this.negativeColor,
      warningColor: warningColor ?? this.warningColor,
      cardColor: cardColor ?? this.cardColor,
      cardColorLight: cardColorLight ?? this.cardColorLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      gradientColors: gradientColors ?? this.gradientColors,
      isDark: isDark ?? this.isDark,
      themeStyle: themeStyle ?? this.themeStyle,
      gradientBackgroundColors:
          gradientBackgroundColors ?? this.gradientBackgroundColors,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      positiveColor: Color.lerp(positiveColor, other.positiveColor, t)!,
      negativeColor: Color.lerp(negativeColor, other.negativeColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      cardColorLight: Color.lerp(cardColorLight, other.cardColorLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      gradientColors: [
        Color.lerp(gradientColors[0], other.gradientColors[0], t)!,
        Color.lerp(gradientColors[1], other.gradientColors[1], t)!,
      ],
      isDark: t < 0.5 ? isDark : other.isDark,
      themeStyle: t < 0.5 ? themeStyle : other.themeStyle,
      gradientBackgroundColors: [
        Color.lerp(
            gradientBackgroundColors[0], other.gradientBackgroundColors[0], t)!,
        Color.lerp(
            gradientBackgroundColors[1], other.gradientBackgroundColors[1], t)!,
      ],
    );
  }
}

// Custom gradient button (güncellenmiş version)
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color>? gradientColors;
  final double? width;
  final double height;
  final double borderRadius;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.gradientColors,
    this.width,
    this.height = 50,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ThemeExtension'dan renkleri al
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final colors = gradientColors ??
        themeExtension?.gradientColors ??
        [AppTheme.primaryColor, AppTheme.accentColor];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
