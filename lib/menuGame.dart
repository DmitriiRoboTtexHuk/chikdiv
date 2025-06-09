import 'package:flutter/material.dart';

import 'Settings.dart' show SettingsScreen;
import 'chooseLVL.dart' show LevelSelectScreen;
import 'game.dart' show ChickDiveGame;
import 'loadError.dart' show WebviewScreen;

class ChickChickDiveMenuScreen extends StatelessWidget {
  const ChickChickDiveMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF201E48),
        body: Stack(
          children: [
            // --- Background ---
            Positioned.fill(
              child: Image.asset(
                'assets/background.png',
                fit: BoxFit.cover,
              ),
            ),
            // --- Fire ---
      
            // --- Privacy Policy Button ---
            Positioned(
              top: 32,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => WebviewScreen(webUrl:"https://chickchickdive.com/privacy-policy.html")),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade900,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Privacy\nPolicy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // --- Title ---
            Positioned(
              top: MediaQuery.of(context).size.height * 0.18,
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
            // --- Chicken ---
      
            // --- Buttons ---
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.18,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _MenuButton(
                    text: 'PLAY NOW',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LevelSelectScreen()),
                      );

                    },
                  ),
                  const SizedBox(height: 20),
                  _MenuButton(
                    text: 'SETTINGS',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) =>     SettingsScreen()),
                      );
      
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Кнопка как на картинке
class _MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _MenuButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.shade800,
            width: 4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}