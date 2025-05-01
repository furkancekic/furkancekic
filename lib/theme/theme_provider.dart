// theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Remove your custom ThemeMode enum and use Flutter's built-in one
// Flutter's ThemeMode enum has: light, dark, system
enum ColorPalette { blue, purple, green, orange, red }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ColorPalette _colorPalette = ColorPalette.blue;

  // Getter
  ThemeMode get themeMode => _themeMode;
  ColorPalette get colorPalette => _colorPalette;

  // Temel tema seçimi
  ThemeData get theme {
    if (_themeMode == ThemeMode.light) {
      return AppTheme.getLightTheme(_colorPalette);
    } else {
      return AppTheme.getDarkTheme(_colorPalette);
    }
  }

  // Tema modunu değiştir
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  // Renk paletini değiştir
  void setColorPalette(ColorPalette palette) {
    _colorPalette = palette;
    _saveSettings();
    notifyListeners();
  }

  // Başlangıçta kayıtlı tercihleri yükle
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        prefs.getBool('isDarkMode') ?? true ? ThemeMode.dark : ThemeMode.light;

    final paletteIndex = prefs.getInt('colorPalette') ?? 0;
    _colorPalette = ColorPalette.values[paletteIndex];

    notifyListeners();
  }

  // Kullanıcı tercihlerini kaydet
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    prefs.setInt('colorPalette', _colorPalette.index);
  }

  // Demo için tema değiştir (önizleme için)
  ThemeData previewTheme(ThemeMode mode, ColorPalette palette) {
    if (mode == ThemeMode.light) {
      return AppTheme.getLightTheme(palette);
    } else {
      return AppTheme.getDarkTheme(palette);
    }
  }
}
