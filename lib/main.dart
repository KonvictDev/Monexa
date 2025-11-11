import 'dart:async';
import 'package:billing/services/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'auth_wrapper.dart';
import 'screens/splash/splash_screen.dart';
import 'model/expense.dart';
import 'model/order.dart';
import 'model/order_item.dart';
import 'model/product.dart';
import 'model/customer.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  // Use runZonedGuarded to catch all Dart errors
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // --- Crashlytics Setup ---
    if (kDebugMode) {
      // Don't report errors in debug mode
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      // Pass all Flutter errors to Crashlytics in release mode
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      };
      // Pass all Dart errors (async) to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
    // --- End Crashlytics Setup ---

// 🚀 NEW: Initialize and fetch Firebase Remote Config
    await setupRemoteConfig();

    // --- Hive Initialization ---
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(OrderAdapter());
    Hive.registerAdapter(OrderItemAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(CustomerAdapter());

    await Hive.openBox<Product>('products');
    await Hive.openBox<Order>('orders');
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Customer>('customers');
    await Hive.openBox('settings');

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    // This catches errors outside the Flutter framework
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeSettingsAsync = ref.watch(themeSettingsProvider);

    return themeSettingsAsync.when(
      data: (themeSettings) {
        final themeMode = themeSettings.themeMode;
        final colorSeed = themeSettings.colorSeed;

        return MaterialApp(
          title: 'Monexa',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            colorSchemeSeed: colorSeed,
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: 'Inter',
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: colorSeed,
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: 'Inter',
          ),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: _showSplash
                ? const SplashScreen()
                : const AuthWrapper(),
          ),
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (err, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Theme error: $err'))),
      ),
    );
  }
}