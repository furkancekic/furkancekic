// screens/theme_settings_screen.dart
// Güncellenmiş versiyon - Tema stili seçimi ile

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_styles.dart';
import '../widgets/common_widgets.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  // Preview değişkenleri
  ThemeMode? _previewThemeMode;
  ColorPalette? _previewColorPalette;
  ThemeStyle? _previewThemeStyle;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    // Mevcut veya önizleme değerleri
    final currentThemeMode = _previewThemeMode ?? themeProvider.themeMode;
    final currentColorPalette =
        _previewColorPalette ?? themeProvider.colorPalette;
    final currentThemeStyle = _previewThemeStyle ?? themeProvider.themeStyle;

    return Theme(
      data: _previewThemeMode != null ||
              _previewColorPalette != null ||
              _previewThemeStyle != null
          ? themeProvider.previewTheme(
              currentThemeMode,
              currentColorPalette,
              currentThemeStyle,
            )
          : Theme.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tema Ayarları'),
          actions: [
            if (_previewThemeMode != null ||
                _previewColorPalette != null ||
                _previewThemeStyle != null)
              TextButton(
                onPressed: () {
                  // Değişiklikleri kaydet
                  if (_previewThemeMode != null) {
                    themeProvider.setThemeMode(_previewThemeMode!);
                  }
                  if (_previewColorPalette != null) {
                    themeProvider.setColorPalette(_previewColorPalette!);
                  }
                  if (_previewThemeStyle != null) {
                    themeProvider.setThemeStyle(_previewThemeStyle!);
                  }
                  Navigator.pop(context);
                },
                child:
                    const Text('Kaydet', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tema Stili Seçimi
              _buildSectionTitle('Tema Stili', themeExtension),
              const SizedBox(height: 16),
              _buildThemeStyleSelector(currentThemeStyle, themeExtension),

              const SizedBox(height: 32),

              // Tema Modu (Karanlık/Aydınlık)
              _buildSectionTitle('Tema Modu', themeExtension),
              const SizedBox(height: 16),
              _buildThemeModeSelector(currentThemeMode, themeExtension),

              const SizedBox(height: 32),

              // Renk Paleti
              _buildSectionTitle('Renk Paleti', themeExtension),
              const SizedBox(height: 16),
              _buildColorPaletteSelector(currentColorPalette, themeExtension),

              const SizedBox(height: 32),

              // Önizleme Kartları
              _buildSectionTitle('Önizleme', themeExtension),
              const SizedBox(height: 16),
              _buildPreviewCards(themeExtension),

              const SizedBox(height: 32),

              // Sıfırlama Butonu
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _previewThemeMode = null;
                      _previewColorPalette = null;
                      _previewThemeStyle = null;
                    });
                    themeProvider.setThemeMode(ThemeMode.dark);
                    themeProvider.setColorPalette(ColorPalette.blue);
                    themeProvider.setThemeStyle(ThemeStyle.modern);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Varsayılanlara Dön'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppThemeExtension? themeExtension) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildThemeStyleSelector(
      ThemeStyle currentStyle, AppThemeExtension? themeExtension) {
    return Row(
      children: [
        Expanded(
          child: _buildThemeStyleOption(
            'Modern',
            'Keskin hatlar ve neon vurgular',
            ThemeStyle.modern,
            currentStyle == ThemeStyle.modern,
            Icons.dashboard,
            themeExtension,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildThemeStyleOption(
            'Glassmorphism',
            'Cam efekti ve yumuşak geçişler',
            ThemeStyle.glassmorphism,
            currentStyle == ThemeStyle.glassmorphism,
            Icons.blur_on,
            themeExtension,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeStyleOption(
    String title,
    String description,
    ThemeStyle style,
    bool isSelected,
    IconData icon,
    AppThemeExtension? themeExtension,
  ) {
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _previewThemeStyle = style;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : textSecondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeSelector(
      ThemeMode currentMode, AppThemeExtension? themeExtension) {
    return Row(
      children: [
        Expanded(
          child: _buildThemeModeOption(
            'Karanlık',
            ThemeMode.dark,
            currentMode == ThemeMode.dark,
            Icons.dark_mode,
            themeExtension,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildThemeModeOption(
            'Aydınlık',
            ThemeMode.light,
            currentMode == ThemeMode.light,
            Icons.light_mode,
            themeExtension,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeOption(
    String title,
    ThemeMode mode,
    bool isSelected,
    IconData icon,
    AppThemeExtension? themeExtension,
  ) {
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _previewThemeMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : textPrimary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteSelector(
      ColorPalette currentPalette, AppThemeExtension? themeExtension) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ColorPalette.values.map((palette) {
        return _buildColorOption(
          palette,
          currentPalette == palette,
          themeExtension,
        );
      }).toList(),
    );
  }

  Widget _buildColorOption(
    ColorPalette palette,
    bool isSelected,
    AppThemeExtension? themeExtension,
  ) {
    final colors = _getPaletteColors(palette);
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _previewColorPalette = palette;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors[1] : Colors.transparent,
            width: 3,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  List<Color> _getPaletteColors(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.blue:
        return [const Color(0xFF0D47A1), const Color(0xFF00E5FF)];
      case ColorPalette.purple:
        return [const Color(0xFF6200EA), const Color(0xFFBA68C8)];
      case ColorPalette.green:
        return [const Color(0xFF2E7D32), const Color(0xFF69F0AE)];
      case ColorPalette.orange:
        return [const Color(0xFFE65100), const Color(0xFFFFAB40)];
      case ColorPalette.red:
        return [const Color(0xFFB71C1C), const Color(0xFFFF5252)];
    }
  }

  Widget _buildPreviewCards(AppThemeExtension? themeExtension) {
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Column(
      children: [
        // Örnek Kart
        AdaptiveCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AAPL',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Apple Inc.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$175.43',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const StockPriceChange(
                    priceChange: 2.45,
                    percentChange: 1.42,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Butonlar
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Gradient Buton',
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Normal Buton'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Glow Text
        Center(
          child: GlowingText(
            'Parlayan Metin Efekti',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            glowColor: accentColor,
          ),
        ),
      ],
    );
  }
}
