// lib/widgets/app_drawer.dart - Fund navigation eklendi
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/theme_settings_screen.dart';
import '../screens/portfolio_screen.dart';
import '../screens/fund_screens/fund_main_screen.dart';
import '../screens/fund_screens/fund_market_overview_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Temayı al
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();

    // Temadan renkleri al
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Drawer(
      backgroundColor: cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  accentColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kullanıcı Adı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'kullanici@email.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: accentColor),
            title: Text('Ana Sayfa', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: Icon(Icons.show_chart, color: accentColor),
            title: Text('Grafik Ekranı', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/chart');
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics, color: accentColor),
            title:
                Text('Backtest Ekranı', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/backtest');
            },
          ),
          ListTile(
            leading: Icon(Icons.movie, color: accentColor),
            title: Text('Stock Reel', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reels');
            },
          ),
          // Fund related menu items
          const Divider(),
          ListTile(
            leading: Icon(Icons.account_balance, color: accentColor),
            title:
                Text('Yatırım Fonları', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundMainScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics_outlined, color: accentColor),
            title:
                Text('Fon Pazar Analizi', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundMarketOverviewScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: accentColor),
            title: Text('Portfolio', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PortfolioScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.color_lens, color: accentColor),
            title: Text('Tema Ayarları', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: accentColor),
            title: Text('Ayarlar', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              // Ayarlar ekranı navigasyonu
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: accentColor),
            title: Text('Çıkış Yap', style: TextStyle(color: textPrimary)),
            onTap: () {
              Navigator.pop(context);
              // Çıkış işlemleri
            },
          ),
        ],
      ),
    );
  }
}
