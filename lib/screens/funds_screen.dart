// lib/screens/funds_screen.dart
import 'package:flutter/material.dart';
import 'fund_list_screen.dart';

/// Ana fon ekranı - FundListScreen'i wrap eder
class FundsScreen extends StatelessWidget {
  const FundsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FundsScreen sadece FundListScreen'i wrap eder
    // ThemeProvider erişimi FundListScreen içinde gerçekleşir
    return const FundListScreen();
  }
}
