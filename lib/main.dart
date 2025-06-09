import 'dart:io';

import 'package:chikchikdive/pushPermissions.dart' show ChickDivePromoScreen;
import 'package:chikchikdive/menuGame.dart' show ChickChickDiveMenuScreen;
import 'package:chikchikdive/loadError.dart' show WebviewScreen;
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_messaging/firebase_messaging.dart' show FirebaseMessaging, RemoteMessage;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' show InAppWebViewController;
import 'package:timezone/data/latest.dart' as tz show initializeTimeZones;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'badInternet.dart' show NoInternetScreen;

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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ConnectivitySwitcher(),
    );
  }
}

class ConnectivitySwitcher extends StatelessWidget {
  const ConnectivitySwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final connected = snapshot.data != ConnectivityResult.none;
        if (!snapshot.hasData) {
          return const ChickDivePromoScreen();
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
      return const ChickDivePromoScreen();
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