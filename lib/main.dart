// main.dart - Güncellenen navigation ile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
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
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Create theme provider
  final themeProvider = ThemeProvider();

  // Load saved settings
  await themeProvider.loadSettings();

  runApp(
    // Wrap app with Provider
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Modern Finance',
      theme: themeProvider.theme,
      debugShowCheckedModeBanner: false,
      // Ana sayfa olarak HomeScreen'i kullan
      home: const HomeScreen(),
      routes: {
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
    );
  }
}
