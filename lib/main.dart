import 'dart:async';
import 'package:billing/services/remote_config_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'auth_wrapper.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'model/expense.dart';
import 'model/order.dart';
import 'model/order_item.dart';
import 'model/product.dart';
import 'model/customer.dart';
import 'providers/theme_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// TOP-LEVEL FUNCTION: Background message handler (runs in its own isolate)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Must re-initialize Firebase if you need to access any Firebase services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

// Local Notification Initialization
Future<void> initializeLocalNotifications() async {
  // For Android, use your app's launcher icon
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // For iOS/macOS
  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // Handle notification tap when the app is in the foreground
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      // TODO: Handle navigation based on notificationResponse.payload if needed
    },
  );
}

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    await setupRemoteConfig();

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

    await initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
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
    // 1. Start FCM Setup
    _initializeFCM();
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  // 🔥 NEW: Method to display a visible notification when the app is in the foreground
  void _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // IMPORTANT: The channel ID here must match the ID used in the Android setup
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel', // Channel ID
      'High Importance Notifications', // Channel Name (visible to user)
      channelDescription: 'Used for important app alerts.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode, // Unique ID for the notification
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: message.data.toString(), // Pass message data for handling taps
    );
  }

  // 🔥 NEW: Method to initialize FCM listeners and get the token
  void _initializeFCM() async {
    final FirebaseMessaging fcm = FirebaseMessaging.instance;

    // Request Permissions
    NotificationSettings settings = await fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Get the FCM Token
    String? token = await fcm.getToken();
    if (kDebugMode) {
      print('FCM Token: $token');
    }
    // TODO: Send this token to your server!

    // Listen for Token Refresh
    fcm.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('Token refreshed: $newToken');
      }
      // TODO: Send the new token to your server
    });

    // A. Foreground Messages (App is open and visible)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
      }
      if (message.notification != null) {
        // Use local notifications to display the message visually
        _showLocalNotification(message);
      }
    });

    // B. Interaction Handler (User taps notification in background/terminated state)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A notification was opened/tapped!');
        print('Message data: ${message.data}');
      }
      // TODO: Implement navigation logic based on message.data
    });

    // C. Handle App Launch from Terminated State
    fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App launched from terminated state by tapping notification: ${message.data}');
        }
        // TODO: Handle navigation for the initial message
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build method ...
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