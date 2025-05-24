// main.dart - İki tema sistemi ile güncellenmiş

import 'widgets/optimized_navigation_bars.dart'; // SimpleNavigationProvider için
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme/theme_provider.dart';
import 'screens/screener_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/stock_reels_screen.dart';
import 'screens/backtesting_screen.dart';
import 'screens/theme_settings_screen.dart';
import 'screens/benchmark_comparison_screen.dart';
import 'screens/fund_screens/fund_main_screen.dart';
import 'screens/fund_screens/fund_detail_screen.dart';
import 'screens/fund_screens/fund_category_screen.dart';
import 'screens/fund_screens/fund_market_overview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Create theme providers
  final themeProvider = ThemeProvider();

  // Load saved settings
  await themeProvider.loadSettings();

  runApp(
    // Multi Provider için
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(
            create: (_) => SimpleNavigationProvider()), // YENİ
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Her iki provider'ı da dinle
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Radikal mod aktifse onun temasını kullan
    final activeTheme = themeProvider.theme;

    // Status bar style'ı ayarla
    final brightness = (themeProvider.themeMode == ThemeMode.light
        ? Brightness.dark
        : Brightness.light);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness,
      ),
    );

    return MaterialApp(
      title: 'Modern Finance',
      theme: activeTheme,
      debugShowCheckedModeBanner: false,
      // Ana sayfa seçimi - TEST İÇİN DEĞİŞTİRİLDİ
      home: const HomeScreen(), // ← DEMO EKRANI ANA SAYFA YAPILDI
      // Normal kullanım için: home: const HomeScreen(),
      routes: {
        '/home': (context) =>
            const HomeScreen(), // ← HomeScreen route olarak eklendi
        '/chart': (context) => const ChartScreen(),
        '/screener': (context) => const ScreenerScreen(),
        '/backtest': (context) => const BacktestingScreen(),
        '/reels': (context) => const StockReelsScreen(),
        '/theme': (context) => const ThemeSettingsScreen(),
        '/benchmark': (context) => const BenchmarkComparisonScreen(),
        // Fund routes
        '/funds': (context) => const FundMainScreen(),
        '/fund_market_overview': (context) => const FundMarketOverviewScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes with arguments
        switch (settings.name) {
          case '/fund_detail':
            final fund = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => FundDetailScreen(fund: fund),
            );
          case '/fund_category':
            final category = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => FundCategoryScreen(category: category),
            );
          default:
            return null;
        }
      },
      // Tema geçişlerinde animasyon
      builder: (context, child) {
        return AnimatedTheme(
          data: activeTheme,
          duration: const Duration(milliseconds: 300),
          child: child!,
        );
      },
    );
  }
}
