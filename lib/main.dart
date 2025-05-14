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
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/chart': (context) => const ChartScreen(),
          '/screener': (context) => const ScreenerScreen(),
          '/backtest': (context) => const BacktestingScreen(),
          '/reels': (context) => const StockReelsScreen(),
          '/theme': (context) => const ThemeSettingsScreen(),
          '/benchmark': (context) => const BenchmarkComparisonScreen(),
        });
  }
}
