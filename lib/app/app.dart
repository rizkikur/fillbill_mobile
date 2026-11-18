import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class FillBillApp extends StatelessWidget {
  const FillBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FillBill',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

