// lib/screens/funds_screen.dart
import 'package:flutter/material.dart';
import 'fund_list_screen.dart';
import '../theme/app_theme.dart';

/// Ana fon ekranı - FundListScreen'i wrap eder
class FundsScreen extends StatelessWidget {
  const FundsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const FundListScreen();
  }
}

// Bu dosya ana navigation'a Funds sekmesi olarak eklenir
