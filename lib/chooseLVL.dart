import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game.dart' show ChickDiveGame;

const int maxLevels = 10;

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({Key? key}) : super(key: key);

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int maxUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadMaxLevel();
  }

  Future<void> _loadMaxLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      maxUnlockedLevel = prefs.getInt('maxUnlockedLevel') ?? 1;
    });
  }

  Future<void> _updateMaxLevel(int newLevel) async {
    final prefs = await SharedPreferences.getInstance();
    if (newLevel > maxUnlockedLevel) {
      await prefs.setInt('maxUnlockedLevel', newLevel);
      setState(() {
        maxUnlockedLevel = newLevel;
      });
    }
  }

  void _openLevel(BuildContext context, int level) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChickDiveGame(initialLevel: level),
      ),
    );
    if (result is int && result > maxUnlockedLevel) {
      await _updateMaxLevel(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [];
    for (int row = 0; row < 4; row++) {
      List<Widget> rowBubbles = [];
      for (int col = 0; col < 3; col++) {
        int num = row * 3 + col + 1;
        if (num > maxLevels) break;
        bool unlocked = num <= maxUnlockedLevel;
        rowBubbles.add(
          Expanded(
            child: LevelBubble(
              level: num,
              unlocked: unlocked,
              onTap: unlocked
                  ? () => _openLevel(context, num)
                  : null,
            ),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < rowBubbles.length; i++) ...[
                if (i != 0) const SizedBox(width: 12),
                rowBubbles[i],
              ]
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/bg.png', fit: BoxFit.cover)),
          Positioned(
            left: 0, right: 0, top: 70,
            child: Center(
              child: Text(
                "CHOOSE\nLEVEL",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: Colors.blue.shade900, blurRadius: 7, offset: Offset(0, 5)),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: 210,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: rows,
              ),
            ),
          ),

          // Кнопка назад (иконка или своя картинка)
          Positioned(
            top: 36,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 32),
                  // Или замени на свою иконку:
                  // child: Image.asset('assets/btn_back.png', width: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LevelBubble extends StatelessWidget {
  final int level;
  final bool unlocked;
  final VoidCallback? onTap;
  const LevelBubble({
    Key? key,
    required this.level,
    required this.unlocked,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final img = unlocked ? 'assets/bubble_active.png' : 'assets/bubble_locked.png';
    final textColor = unlocked ? Colors.white : Colors.white.withOpacity(0.6);
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            img,
            width: 95, height: 95,
          ),
          Text(
            '$level',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: textColor,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.55), blurRadius: 5, offset: Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}