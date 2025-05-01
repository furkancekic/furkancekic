import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late ThemeMode _selectedThemeMode;
  late ColorPalette _selectedColorPalette;

  @override
  void initState() {
    super.initState();
    // Mevcut ayarları al
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedThemeMode = themeProvider.themeMode;
    _selectedColorPalette = themeProvider.colorPalette;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Güncel tema ve uzantıyı al
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    
    // Varsayılan renkler
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final cardColorLight = themeExtension?.cardColorLight ?? AppTheme.cardColorLight;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema Ayarları'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tema Modu Seçimi
              Text(
                'Tema Modu',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _themeModeOption(
                      title: 'Koyu Tema',
                      icon: Icons.dark_mode,
                      isSelected: _selectedThemeMode == ThemeMode.dark,
                      onTap: () {
                        setState(() {
                          _selectedThemeMode = ThemeMode.dark;
                        });
                        themeProvider.setThemeMode(ThemeMode.dark);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _themeModeOption(
                      title: 'Aydınlık Tema',
                      icon: Icons.light_mode,
                      isSelected: _selectedThemeMode == ThemeMode.light,
                      onTap: () {
                        setState(() {
                          _selectedThemeMode = ThemeMode.light;
                        });
                        themeProvider.setThemeMode(ThemeMode.light);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Renk Paleti Seçimi
              Text(
                'Renk Paleti',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Mavi Paleti
              _colorPaletteOption(
                title: 'Mavi',
                palette: ColorPalette.blue,
                onTap: () {
                  setState(() {
                    _selectedColorPalette = ColorPalette.blue;
                  });
                  themeProvider.setColorPalette(ColorPalette.blue);
                },
              ),
              
              const SizedBox(height: 12),
              
              // Mor Paleti
              _colorPaletteOption(
                title: 'Mor',
                palette: ColorPalette.purple,
                onTap: () {
                  setState(() {
                    _selectedColorPalette = ColorPalette.purple;
                  });
                  themeProvider.setColorPalette(ColorPalette.purple);
                },
              ),
              
              const SizedBox(height: 12),
              
              // Yeşil Paleti
              _colorPaletteOption(
                title: 'Yeşil',
                palette: ColorPalette.green,
                onTap: () {
                  setState(() {
                    _selectedColorPalette = ColorPalette.green;
                  });
                  themeProvider.setColorPalette(ColorPalette.green);
                },
              ),
              
              const SizedBox(height: 12),
              
              // Turuncu Paleti
              _colorPaletteOption(
                title: 'Turuncu',
                palette: ColorPalette.orange,
                onTap: () {
                  setState(() {
                    _selectedColorPalette = ColorPalette.orange;
                  });
                  themeProvider.setColorPalette(ColorPalette.orange);
                },
              ),
              
              const SizedBox(height: 12),
              
              // Kırmızı Paleti
              _colorPaletteOption(
                title: 'Kırmızı',
                palette: ColorPalette.red,
                onTap: () {
                  setState(() {
                    _selectedColorPalette = ColorPalette.red;
                  });
                  themeProvider.setColorPalette(ColorPalette.red);
                },
              ),
              
              const SizedBox(height: 32),
              
              // Örnek UI Bileşenleri
              Text(
                'Önizleme',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Örnek Kart
              FuturisticCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Örnek Kart',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu bir örnek karttır ve seçtiğiniz temayı gösterir.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const StockPriceChange(
                          priceChange: 2.5,
                          percentChange: 1.8,
                          showIcon: true,
                        ),
                        const Spacer(),
                        const StockPriceChange(
                          priceChange: -1.2,
                          percentChange: -0.9,
                          showIcon: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GradientButton(
                      text: 'Buton Örneği',
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
              
              GlowingText(
                'Bu parlayan bir metin örneğidir',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeModeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final cardColorLight = themeExtension?.cardColorLight ?? AppTheme.cardColorLight;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? cardColorLight : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : null,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? accentColor : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorPaletteOption({
    required String title,
    required ColorPalette palette,
    required VoidCallback onTap,
  }) {
    // Paleteyi önizle
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final previewTheme = themeProvider.previewTheme(_selectedThemeMode, palette);
    final themeExtension = previewTheme.extension<AppThemeExtension>();
    
    final primaryColor = themeExtension?.primaryColor ?? AppTheme.primaryColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    
    final isSelected = _selectedColorPalette == palette;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: previewTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Renk Önizleme
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? accentColor : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: accentColor,
              ),
          ],
        ),
      ),
    );
  }
}