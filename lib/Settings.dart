import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menuGame.dart' show ChickChickDiveMenuScreen;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = true;
  bool vibroEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      vibroEnabled = prefs.getBool('vibroEnabled') ?? true;
    });
  }

  Future<void> _setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    setState(() => soundEnabled = value);
  }

  Future<void> _setVibroEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibroEnabled', value);
    setState(() => vibroEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Затемнение
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.65)),
        ),
        // Центрированное окно с фоном-картинкой
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/ramka.png', // путь к твоей рамке-фону (4-я картинка)
                width: 360,
                height: 360,
                fit: BoxFit.contain,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Картинка заголовка
                    Image.asset('assets/settings_title.png', width: 260, fit: BoxFit.contain),
                    const SizedBox(height: 30),
                    // SOUND row
                    Row(
                      children: [
                        Image.asset('assets/sound_label.png', height: 40),
                        const Spacer(),
                        _CustomSwitch(
                          value: soundEnabled,
                          onChanged: (v) => _setSoundEnabled(!soundEnabled),
                          activeColor: Colors.green,
                          inactiveColor: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // VIBRO row
                    Row(
                      children: [
                        Image.asset('assets/vibro_label.png', height: 40),
                        const Spacer(),
                        _CustomSwitch(
                          value: vibroEnabled,
                          onChanged: (v) => _setVibroEnabled(!vibroEnabled),
                          activeColor: Colors.green,
                          inactiveColor: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    // Кнопки
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FancyButton(
                          text: "BACK TO MENU",
                          onTap: () => {
                          Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) =>    ChickChickDiveMenuScreen()),
                          )
                          },
                        ),
                     /*   _FancyButton(
                          text: "START AGAIN",
                          onTap: () => Navigator.pop(context, "restart"),
                        ),*/
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Кастомный тумблер
class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  const _CustomSwitch({
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: value ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 56,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: value ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Красивая кнопка
class _FancyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _FancyButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 1,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}