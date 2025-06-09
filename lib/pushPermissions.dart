import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    show AuthorizationStatus, FirebaseMessaging, NotificationSettings;

import 'loading.dart' show ChickDiveLoadingScreen;

class ChickDivePromoScreen extends StatefulWidget {
  const ChickDivePromoScreen({super.key});

  @override
  State<ChickDivePromoScreen> createState() => _ChickDivePromoScreenState();
}

class _ChickDivePromoScreenState extends State<ChickDivePromoScreen> {
  bool _loading = false;
  bool _waitingForBananaToken = false;
  bool _buttonsVisible = true;
  String _statusText = "";
  MethodChannel? _bananaChannel;

  void listenForBananaToken(Function(String token) onBananaToken) {
    _bananaChannel = const MethodChannel('com.example.fcm/token');
    _bananaChannel!.setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String token = call.arguments as String;
        onBananaToken(token);
      }
    });
  }

  Future<void> _onAllowPressed() async {
    setState(() {
      _loading = true;
      _statusText = "Requesting notification permission...";
      _buttonsVisible = false;
    });

    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Ждём токен, если разрешено, иначе просто идём дальше с пустым токеном
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      setState(() {
        _waitingForBananaToken = true;
        _loading = true;
        _statusText = "...";
      });

      listenForBananaToken((token) {
        if (mounted) {
          setState(() {
            _waitingForBananaToken = false;
            _loading = false;
          });
          _proceed(token);
        }
      });
    } else {
      // отказано
      _proceed("");
    }
  }

  void _proceed(String token) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChickDiveLoadingScreen(token),
      ),
    );
  }

  @override
  void dispose() {
    _bananaChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E48),
      body: Stack(
        children: [
          // --- Background PNG ---
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // --- Loading overlay ---
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
          // --- Остальной контент поверх ---
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
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
                      const SizedBox(height: 18),

                      const SizedBox(height: 36),
                      if (_buttonsVisible)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _onAllowPressed,
                              child: Container(
                                width: double.infinity,
                                padding:
                                const EdgeInsets.symmetric(vertical: 20),
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
        ],
      ),
    );
  }
}