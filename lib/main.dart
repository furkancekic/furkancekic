import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
// HomeScreen import edildi
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import '../screens/screener_screen.dart';
import '../screens/chart_screen.dart';
import '../screens/stock_reels_screen.dart';
import '../screens/backtesting_screen.dart'; // Bu satırı ekleyin
import '../screens/theme_settings_screen.dart'; // Bu satırı ekleyin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ekran yönlendirmesini ayarla
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Tema sağlayıcısını oluştur
  final themeProvider = ThemeProvider();

  // Kaydedilmiş ayarları yükle
  await themeProvider.loadSettings();

  runApp(
    // Provider ile uygulamayı saralım
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
    // ThemeProvider'a erişim
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
        // ...
        // home: const HomeScreen(), // Bu satırı kaldırın
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/chart': (context) => const ChartScreen(),
          '/screener': (context) => const ScreenerScreen(),
          '/backtest': (context) => const BacktestingScreen(),
          '/reels': (context) => const StockReelsScreen(),
          '/theme': (context) => const ThemeSettingsScreen(),
        });
  }
}
