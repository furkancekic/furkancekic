import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
// HomeScreen import edildi
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

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
        title: 'Modern Finance',
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.getLightTheme(themeProvider.colorPalette),
        darkTheme: AppTheme.getDarkTheme(themeProvider.colorPalette),
        home: const HomeScreen(),
        routes: {
          '/': (context) =>
              const HomeScreen(), // Ana sayfa olarak HomeScreen ayarlandı
        });
  }
}
