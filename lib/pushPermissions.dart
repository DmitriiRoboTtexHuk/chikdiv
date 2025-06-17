import 'dart:convert' show json, Encoding;
import 'dart:ui' show window;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    show AuthorizationStatus, FirebaseMessaging, NotificationSettings, RemoteMessage;
import 'package:http/http.dart' as http show post;
import 'package:shared_preferences/shared_preferences.dart';

import 'loadError.dart';
import 'loading.dart' show ChickDiveLoadingScreen;
import 'menuGame.dart';

class ChickDivePromoScreen extends StatefulWidget {
  final Map<String, dynamic> payload;
  String af_id;

 ChickDivePromoScreen({super.key, required this.payload,required this.af_id});

  @override
  State<ChickDivePromoScreen> createState() => _ChickDivePromoScreenState();
}

class _ChickDivePromoScreenState extends State<ChickDivePromoScreen> {
  bool _loading = false;
  bool _waitingForBananaToken = false;
  bool _buttonsVisible = true;
  String _statusText = "";
  MethodChannel? _bananaChannel;
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

  final String bundle = 'com.chikchikdive.koopk.chikchikdive';
  Future<String?> listenForBananaToken() async {
    _bananaChannel = const MethodChannel('com.example.fcm/token');
    try {
      final token = await _bananaChannel!.invokeMethod('requestToken');
      if (token != null && token is String) {
        setState(() {
          fcmToken = token;
        });
        return token;
      }
    } catch (e) {
      print("Ошибка получения FCM токена: $e");
      // Можно обработать ошибку или вернуть null
    }



  }
  /// Инициализация Firebase Messaging + обработка пушей
  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    fcmToken = await messaging.getToken();
    firebaseId = await messaging.getToken(); // или получите через firebase_installations
   print("Firebase ID "+firebaseId.toString());
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
   //   _showTopNotification(context, message, imageUrl);
    });

    // App opened from push
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['uri'] != null) {
        deep = message.data['uri'];
     //   SetUrl(message.data['uri'].toString());
      }
    });
  }
  Future<void> _onAllowPressed() async {
    setState(() {
      _loading = true;
      _statusText = "...";
      _buttonsVisible = false;
    });

    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      setState(() {
        _waitingForBananaToken = true;
        _loading = true;
        _statusText = "...";
      });

      final token = await listenForBananaToken();
      setState(() {
        _waitingForBananaToken = false;
        _loading = false;
      });

      if (token != null) {
        // тут токен уже есть, можно отправлять
        _sendPostWithAppsFlyerData(widget.payload);
      } else {
        // обработка ошибки
        print("FCM токен не получен");
        _sendPostWithAppsFlyerData(widget.payload); // или не отправлять
      }
    } else {
      _sendPostWithAppsFlyerData(widget.payload);
    }
  }
  void _proceed(String token) {
    _sendPostWithAppsFlyerData(widget.payload);

  }
@override
  void initState() {
    setState(() {
      language = window.locale.toLanguageTag(); // например, "en-US"
    });

    super.initState();
  }
  @override
  void dispose() {
    _bananaChannel?.setMethodCallHandler(null);
    super.dispose();
  }


  Future<void> _sendPostWithAppsFlyerData(Map<String, dynamic> appsFlyerData) async {

    final url = Uri.parse('https://chickchickdive.com/config.php');
    final headers = {'Content-Type': 'application/json'};
print("paydata2 "+appsFlyerData.toString());
    final Map<String, dynamic> requestData = {
      // ... ваши поля ...
      "adset": appsFlyerData["adset"] ?? "",
      "af_adset": appsFlyerData["af_adset"] ?? "",
      "adgroup": appsFlyerData["adgroup"] ?? "",
      "campaign_id": appsFlyerData["campaign_id"] ?? "",
    //  "af_status": appsFlyerData["af_status"],
           "af_status": "Non-organic",
      "agency": appsFlyerData["agency"] ?? "",
      "af_sub3": appsFlyerData["af_sub3"],
      "af_siteid": appsFlyerData["af_siteid"],
      "adset_id": appsFlyerData["adset_id"] ?? "",
      "is_fb": appsFlyerData["is_fb"] ?? false,
      "is_first_launch": appsFlyerData["is_first_launch"] ?? false,
      "click_time": appsFlyerData["click_time"] ?? "",
      "iscache": appsFlyerData["iscache"] ?? false,
      "ad_id": appsFlyerData["ad_id"] ?? "",
      "af_sub1": appsFlyerData["af_sub1"] ?? "",
      "campaign": appsFlyerData["campaign"] ?? "",
      "is_paid": appsFlyerData["is_paid"] ?? false,
      "af_sub4": appsFlyerData["af_sub4"] ?? "",
      "adgroup_id": appsFlyerData["adgroup_id"] ?? "",
      "is_mobile_data_terms_signed": appsFlyerData["is_mobile_data_terms_signed"] ?? false,
      "af_channel": appsFlyerData["af_channel"] ?? "",
      "af_sub5": appsFlyerData["af_sub5"],
      "media_source": appsFlyerData["media_source"] ?? "",
      "install_time": appsFlyerData["install_time"] ?? "",
      "af_sub2": appsFlyerData["af_sub2"],

      // Дополнительные поля
      "af_id": widget.af_id,
      "firebase_project_id": "211291543724",
      "bundle_id": bundle,
      "store_id": bundle,
      "os": "iOS" ?? "",
      "locale": language ?? "",
      "push_token": fcmToken ?? "",
      "firebase_id": "chik-chik-dive" ?? "",
    };

    print("load JSON ${json.encode(requestData)}");
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestData),
        encoding: Encoding.getByName('utf-8'),
      );
      final prefs = await SharedPreferences.getInstance();
      if (response.statusCode == 200) {
        print("Успешно отправлено: ${response.body}");
        final Map<String, dynamic> respData = json.decode(response.body);

        if (respData["ok"] == true && respData["url"] != null && respData["url"].toString().isNotEmpty) {
          await prefs.setString('bad', respData["url"]);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WebviewScreen(webUrl: respData["url"]),
            ),
          );
        } else {
          await prefs.setString('bad', "");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChickChickDiveMenuScreen(),
            ),
          );
        }
      } else {
        await prefs.setString('bad', "");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChickChickDiveMenuScreen(),
          ),
        );
        print("Ошибка при отправке: ${response.statusCode} — ${response.body}");
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bad', "");
      print("Ошибка отправки: $e");
    }
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
            // --- Background (фон всегда на весь экран) ---
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

            // --- Loading overlay (если нужно) ---
            if (_loading || _waitingForBananaToken)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        if (_statusText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              _statusText,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // --- Контент по центру, прокручиваемый, с фиксированной шириной ---
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: contentWidth,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      // Заголовок
                      Text(
                        'CHICK\nCHICK\nDIVE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 54,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Colors.yellow.shade400,
                          shadows: [
                            const Shadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange.shade200,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 18),
                            const SizedBox(height: 36),
                            if (_buttonsVisible)
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _onAllowPressed();

                                      _initializeFirebaseMessaging();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade800,
                                            Colors.orange.shade400,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.shade900,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "YES, I WANT BONUSES!",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  GestureDetector(
                                    onTap: () => _proceed(""),
                                    child: const Text(
                                      'SKIP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orangeAccent,
                                        fontSize: 16,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

}