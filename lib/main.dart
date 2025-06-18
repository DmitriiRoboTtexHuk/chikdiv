import 'dart:io';

import 'package:chikchikdive/pushPermissions.dart' show ChickDivePromoScreen;
import 'package:chikchikdive/menuGame.dart' show ChickChickDiveMenuScreen;
import 'package:chikchikdive/loadError.dart' show WebviewScreen;
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_messaging/firebase_messaging.dart' show FirebaseMessaging, RemoteMessage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_inappwebview/flutter_inappwebview.dart' show InAppWebViewController;
import 'package:timezone/data/latest.dart' as tz show initializeTimeZones;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PushLoad.dart' show MainWebScreenPUSH;
import 'badInternet.dart' show NoInternetScreen;
import 'loading.dart' show ChickDiveLoadingScreen;

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final afStatus = prefs.getString('af_status');

    if (afStatus == null || afStatus.isEmpty) {
      // Если нет значения — показываем загрузочный экран
      return ChickDiveLoadingScreen("");
    } else if (afStatus.contains("Non-Organic")) {
      final webUrl = prefs.getString('bad') ?? " ";

      // Если webUrl пустой или состоит только из пробелов, показываем ChickDiveLoadingScreen
      if (webUrl.trim().isEmpty) {
        return ChickDiveLoadingScreen("");
      } else {
        return WebviewScreen(webUrl: webUrl);
      }
    } else if (afStatus.contains("Non-Organic")) {
      return ChickChickDiveMenuScreen();
    } else {
      // На всякий случай fallback — тоже загрузочный экран
      return ChickDiveLoadingScreen("");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data!;
          }
          // Пока грузится — просто сплэш или загрузка
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class ConnectivitySwitcher extends StatefulWidget {
  const ConnectivitySwitcher({super.key});

  @override
  State<ConnectivitySwitcher> createState() => _ConnectivitySwitcherState();
}

class _ConnectivitySwitcherState extends State<ConnectivitySwitcher> {

  @override
  void initState() {
    _setupClownNotificationChannel();
    super.initState();
  }

  void _setupClownNotificationChannel() {
    MethodChannel('com.example.fcm/notification')
        .setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        final url = data["url"];
        if (url != null && !url.contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => MainWebScreenPUSH(webUrl: url)),
                (route) => false,
          );
        }
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    _setupClownNotificationChannel();
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final connected = snapshot.data != ConnectivityResult.none;
        if (!snapshot.hasData) {
          return  ChickDivePromoScreen(payload: {},af_id: "",);
        }
        return connected
            ? const InitialScreenSelector()
            : const NoInternetScreen();
      },
    );
  }
}

class InitialScreenSelector extends StatelessWidget {
  const InitialScreenSelector({super.key});

  Future<Widget> _getStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bad = prefs.getString('bad');
    if (bad == null) {
      // Не было ничего сохранено — показываем первый экран
      return  ChickDivePromoScreen(payload: {},af_id: "",);
    } else if (bad.isEmpty) {
      // Было сохранено пустое — показываем меню
      return ChickChickDiveMenuScreen();
    } else {
      // Было сохранено ссылка — показываем webview
      return WebviewScreen(webUrl: bad);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return snapshot.data!;
        }
        // Лоадер на время ожидания SharedPreferences
        return const Scaffold(
          backgroundColor: Color(0xFF201E48),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}