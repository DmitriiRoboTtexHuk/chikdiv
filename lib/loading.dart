import 'dart:convert';
import 'dart:io';

import 'package:advertising_id/advertising_id.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart' show AppsFlyerOptions, AppsflyerSdk;
import 'package:chikchikdive/pushPermissions.dart';
import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart' show FirebaseMessaging, NotificationSettings, RemoteMessage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'package:timezone/data/latest.dart' as tz;

import 'loadError.dart' show WebviewScreen;
import 'menuGame.dart' show ChickChickDiveMenuScreen;

class ChickDiveLoadingScreen extends StatefulWidget {
  String ? token;
   ChickDiveLoadingScreen(this.token,{super.key});

  @override
  State<ChickDiveLoadingScreen> createState() => _ChickDiveLoadingScreenState(token);
}

class _ChickDiveLoadingScreenState extends State<ChickDiveLoadingScreen> {
  final String token = "087e0aa4-4926-4f76-9b21-d93311646570";
  final String bundle = 'com.chikchikdive.koopk.chikchikdive';
  final String appsDevID = "j7pKmPfoH4MNJMVhRqwM2a";
  // final String firebaseProjectId = "8934278530";
  final String finalUrl = "https://yandex.ru";
  _ChickDiveLoadingScreenState(this.fcmToken);
  // Данные устройства
  String flyerId = "";
  String? advertisingId = "";
  String? fcmToken;
  String? firebaseId;
  String? platform;
  String? language;
  String? osVersion;
  String? deviceId;
  String? appVersion;

  // Для пуш-уведомлений
  String? _notificationTitle;
  String? _notificationBody;
  Map<String, dynamic>? _notificationData;
  String? deep;
  String? _messageTitle;
  String? _messageBody;

  late AppsflyerSdk _appsflyerSdk;
  late InAppWebViewController webViewController;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initAll();
  }

  Future<void> _initAll() async {

    _initAppsFlyer();
    _checkInitialMessage();
    await Firebase.initializeApp();
    await _initPlatformState();
    await _initDeviceInfo();
 //   await _initializeFirebaseMessaging();

  }

  /// Получение advertisingId
  Future<void> _initPlatformState() async {
    try {
      advertisingId = await AdvertisingId.id(true);
    } on PlatformException {
      advertisingId = 'Failed to get platform version.';
    }
  }

  /// Получение информации об устройстве
  Future<void> _initDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      platform = "Android";
      osVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
      platform = "iOS";
      osVersion = iosInfo.systemVersion;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    language = Platform.localeName.split('_')[0];
  }

  /// Инициализация Firebase Messaging + обработка пушей
  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    fcmToken = await messaging.getToken();
    firebaseId = await messaging.getToken(); // или получите через firebase_installations

    // Foreground push
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _notificationTitle = message.notification?.title ?? "No Title";
        _notificationBody = message.notification?.body ?? "No Body";
        _notificationData = message.data;
      });

      final imageUrl =
          message.notification?.android?.imageUrl ??
              message.notification?.apple?.imageUrl;
      _showTopNotification(context, message, imageUrl);
    });

    // App opened from push
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['uri'] != null) {
        deep = message.data['uri'];
        SetUrl(message.data['uri'].toString());
      }
    });
  }

  /// Проверка пуша, который пришел при запуске приложения
  Future<void> _checkInitialMessage() async {
    final RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      setState(() {
        _notificationTitle = initialMessage.notification?.title ?? "No Title";
        _notificationBody = initialMessage.notification?.body ?? "No Body";
        _notificationData = initialMessage.data;
      });

      if (initialMessage.data['uri'] != null) {
        SetUrl(initialMessage.data['uri'].toString());
        setState(() {
          deep = initialMessage.data['uri'];
        });
      } else {
        setemptyUrl();
      }
    } else {
      setemptyUrl();
      setState(() {
        _messageTitle = "No message";
        _messageBody = "No data received at app launch.";
      });
    }
  }

  /// Отрисовка пуша в top overlay
  void _showTopNotification(
      BuildContext context, RemoteMessage? message, final imageUrl) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                  if (message?.data['uri'] != null) {
                    SetUrl(message!.data['uri'].toString());
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),

                        Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (overlayEntry.mounted) {
                              overlayEntry.remove();
                            }
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      message?.notification?.title ?? "",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      message?.notification?.body ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl ?? "https://via.placeholder.com/350x150",
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);
  }

  /// Открытие URL из пуша или сброс на базовый
  void SetUrl(String uri) async {
    //  print("my uri here $finalUrl$uri");
  }

  setemptyUrl() async {
    //   print("LOAD URLT$finalUrl");
    if (webViewController != null) {
      await webViewController.loadUrl(
        urlRequest: URLRequest(url: WebUri(finalUrl)),
      );
    }
  }

  /// Инициализация AppsFlyer и обработка конверсий
  void _initAppsFlyer() {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: appsDevID,
      appId: "6746939213",
      showDebug: true,
    );
    _appsflyerSdk = AppsflyerSdk(options);

    _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    _appsflyerSdk.startSDK(
      onSuccess: () { print("AppsFlyer SDK initialized successfully."); },
      onError: (int errorCode, String errorMessage) {
        print("Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage");
      },
    );

    _appsflyerSdk.getAppsFlyerUID().then((value) {
      setState(() { flyerId = value.toString(); });
    });

// 1. Сначала объяви функцию:
    Future<void> saveAFStatusAndNavigate(String afStatus, BuildContext context, Map<String, dynamic> payload) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('af_status', afStatus);

      print("Payload: $afStatus");

      if (afStatus.contains("Organic")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChickChickDiveMenuScreen(),
          ),
        );
      } else if (afStatus.contains("Non-Organic")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChickDivePromoScreen(payload: payload,af_id: flyerId,),
          ),
        );
      }
    }

// 2. Потом используй:
    _appsflyerSdk.onInstallConversionData((res) {
      Map<String, dynamic> payload = Map<String, dynamic>.from(res['payload']);
      final afStatus = payload["af_status"].toString();
   print("Paydata "+payload.toString());
      // Сохраняем значение асинхронно
      saveAFStatusAndNavigate(afStatus, context, payload);
    });

  }


  @override
  Widget build(BuildContext context) {

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    // Контент
    final double contentWidth = isLandscape ? 430 : double.infinity;

    // Фон
    final double bgHeight = isLandscape ? 1080 : media.size.height;
    final double bgWidth = media.size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF201E48),
      body: Stack(
        children: [
          // --- Background wall ---

          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: bgWidth,
                height: bgHeight,
                child: Image.asset(
                  'assets/background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          // --- Top fire ---

          // --- Window fire ---

          // --- Chicken ---

          // --- Title ---
          Positioned(
            top: MediaQuery.of(context).size.height * 0.23,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'CHICK\nCHICK\nDIVE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 54,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.yellow.shade400,
                  letterSpacing: 1,
                  shadows: const [
                    Shadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0),
                  ],
                ),
              ),
            ),
          ),
          // --- LOADING ---
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.065,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'LOADING',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: Colors.blue.shade900,
                      offset: const Offset(3, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}