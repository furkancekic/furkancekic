// theme/theme_provider.dart
// Güncellenmiş provider - tema stili desteği ile
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'theme_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorPalette { blue, purple, green, orange, red }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ColorPalette _colorPalette = ColorPalette.blue;
  ThemeStyle _themeStyle = ThemeStyle.modern;

  // Getter
  ThemeMode get themeMode => _themeMode;
  ColorPalette get colorPalette => _colorPalette;
  ThemeStyle get themeStyle => _themeStyle;

  // Temel tema seçimi
  ThemeData get theme {
    if (_themeMode == ThemeMode.light) {
      return AppTheme.getLightTheme(_colorPalette, _themeStyle);
    } else {
      return AppTheme.getDarkTheme(_colorPalette, _themeStyle);
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

  // Tema stilini değiştir
  void setThemeStyle(ThemeStyle style) {
    _themeStyle = style;
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

    final styleIndex = prefs.getInt('themeStyle') ?? 0;
    _themeStyle = ThemeStyle.values[styleIndex];

    notifyListeners();
  }

  // Kullanıcı tercihlerini kaydet
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    prefs.setInt('colorPalette', _colorPalette.index);
    prefs.setInt('themeStyle', _themeStyle.index);
  }

  // Demo için tema değiştir (önizleme için)
  ThemeData previewTheme(
      ThemeMode mode, ColorPalette palette, ThemeStyle style) {
    if (mode == ThemeMode.light) {
      return AppTheme.getLightTheme(palette, style);
    } else {
      return AppTheme.getDarkTheme(palette, style);
    }
  }
}
