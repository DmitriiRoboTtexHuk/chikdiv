import 'package:flutter/material.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181C2E),
      body: Stack(
        children: [
          // Фон (замени на свой ассет если нужно)
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Дракон/огонь сверху (если есть)

          // Рамка с текстом
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/gameover_box.png',
                    width: 340,
                    height: 240,
                    fit: BoxFit.fill,
                  ),
                  SizedBox(
                    width: 250,
                    child: Text(
                      "PLEASE, CHECK\nYOUR INTERNET\nCONNECTION AND\nRESTART",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(blurRadius: 5, color: Colors.black, offset: Offset(1, 2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Курица снизу (чуть выходит наверх)

        ],
      ),
    );
  }
}