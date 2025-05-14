// lib/main.dart - Updated to fix Provider context issues
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/funds_screen.dart'; // Import FundsScreen
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
      home: const MainNavigator(), // Use a new widget to handle navigation
      routes: {
        '/chart': (context) => const ChartScreen(),
        '/screener': (context) => const ScreenerScreen(),
        '/backtest': (context) => const BacktestingScreen(),
        '/reels': (context) => const StockReelsScreen(),
        '/funds': (context) => const FundsScreen(), // Funds route
        '/theme': (context) => const ThemeSettingsScreen(),
        '/benchmark': (context) => const BenchmarkComparisonScreen(),
      },
    );
  }
}

// Main Navigator to handle bottom navigation
class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  // List of screens for the main navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const ScreenerScreen(),
    const ChartScreen(),
    const BacktestingScreen(),
    const StockReelsScreen(),
    const FundsScreen(), // Add FundsScreen to navigation
  ];

  @override
  Widget build(BuildContext context) {
    // Since MainNavigator is already under the provider, we can safely pass context
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Screener',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.candlestick_chart),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Backtest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.slideshow),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Funds',
          ),
        ],
      ),
    );
  }
}
