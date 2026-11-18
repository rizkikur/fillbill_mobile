import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/security/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(AppConfig.dev());
  final storage = SecureStorageService();
  await AppConfig.loadSavedMockupPreference(storage);

  runApp(
    const ProviderScope(
      child: FillBillApp(),
    ),
  );
}

