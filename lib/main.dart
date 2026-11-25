import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/preferences_service.dart';
import 'features/alerts/providers/alerts_provider.dart';
import 'features/alerts/services/notification_service.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final sharedPreferences = await SharedPreferences.getInstance();
  final preferencesService = SharedPrefsPreferencesService(sharedPreferences);

  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const BudgetTrackerApp(),
    ),
  );
}
