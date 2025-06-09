import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LevelSelectScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// =============== LEVEL SELECT SCREEN ===============

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({Key? key}) : super(key: key);

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int maxUnlockedLevel = 1;
  static const int maxLevels = 10;

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

  Future<void> _onLevelPassed(int newLevel) async {
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
    if (result is int) {
      await _onLevelPassed(result);
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
          Positioned.fill(child: Container(color: const Color(0xFF201E48))),
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
                    Shadow(color: Colors.blue.shade900, blurRadius: 7, offset: const Offset(0, 5)),
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
                Shadow(color: Colors.black.withOpacity(0.55), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============== CHICK DIVE GAME ===============

enum GameState { start, playing, gameover, paused }

class ChickDiveGame extends StatefulWidget {
  final int initialLevel;
  const ChickDiveGame({Key? key, this.initialLevel = 1}) : super(key: key);

  @override
  State<ChickDiveGame> createState() => _ChickDiveGameState();
}

class _ChickDiveGameState extends State<ChickDiveGame> {
  GameState _gameState = GameState.start;
  double chickenX = 0.5;
  double chickenY = 0.5;
  double bgOffset = 0;
  double moveSpeed = 0.05;
  double baseObjectSpeed = 0.35;
  int score = 0;
  late int level;
  List<Egg> eggs = [];
  List<Fish> fish = [];
  Timer? _gameLoop;
  final Random _rand = Random();
  Size? _screenSize;

  static const double chickenSize = 128;
  static const double eggSizeRatio = 0.1;
  static const double fishSizeRatio = 0.13;
  static const List<int> levelGoals = [
    1000, 2000, 5000, 7000, 10000, 12000, 15000, 17000, 19000, 20000
  ];

  @override
  void initState() {
    super.initState();
    level = widget.initialLevel.clamp(1, levelGoals.length);
    Future.delayed(const Duration(seconds: 3), () {
      setState(() => _gameState = GameState.playing);
      _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _onTick);
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  int get maxLevel => levelGoals.length;
  int get maxEggs => 3 + (level ~/ 2);
  int get maxFish => 2 + level;
  double get objectSpeed => baseObjectSpeed + (level - 1) * 0.12;

  void _onTick(Timer t) {
    if (_screenSize == null) return;

    setState(() {
      bgOffset += objectSpeed;
      if (bgOffset > _screenSize!.height) bgOffset -= _screenSize!.height;

      // 1. Двигаем яйца и рыбы
      for (final egg in eggs) {
        egg.y -= objectSpeed / _screenSize!.height;
      }
      for (final f in fish) {
        f.y -= f.speed / _screenSize!.height;
      }

      // 2. Проверяем сбор яиц и удаляем собранные/ушедшие
      eggs.removeWhere((egg) {
        final cx = _screenSize!.width * chickenX;
        final cy = _screenSize!.height * chickenY + chickenSize / 2;
        final ex = _screenSize!.width * egg.x;
        final ey = _screenSize!.height * egg.y + (_screenSize!.width * egg.size) / 2;
        final dist = sqrt(pow(cx - ex, 2) + pow(cy - ey, 2));
        if (dist < (chickenSize / 2 + _screenSize!.width * egg.size / 2) * 0.7) {
          score += 100;
          _eggVibration();
          _checkLevelUp();
          return true;
        }
        return egg.y < -0.2;
      });

      // 3. Проверяем столкновения с рыбой
      for (final f in fish) {
        final cx = _screenSize!.width * chickenX;
        final cy = _screenSize!.height * chickenY + chickenSize / 2;
        final fx = _screenSize!.width * f.x;
        final fy = _screenSize!.height * f.y + (_screenSize!.width * f.size) / 2;
        final dist = sqrt(pow(cx - fx, 2) + pow(cy - fy, 2));
        if (dist < (chickenSize / 2 + _screenSize!.width * f.size / 2) * 0.7) {
          _gameOver();
          return;
        }
      }
      fish.removeWhere((f) => f.y < -0.2);

      // 4. Генерируем новые яйца и рыбы
      if (eggs.length < maxEggs && _rand.nextDouble() < 0.015) {
        eggs.add(Egg(
          x: 0.1 + _rand.nextDouble() * 0.8,
          y: 1.1,
          size: eggSizeRatio + _rand.nextDouble() * 0.03,
        ));
      }
      if (fish.length < maxFish && _rand.nextDouble() < 0.01 + level * 0.003) {
        fish.add(Fish(
          x: 0.12 + _rand.nextDouble() * 0.76,
          y: 1.13 + _rand.nextDouble() * 0.2,
          size: fishSizeRatio + _rand.nextDouble() * 0.04,
          type: _rand.nextBool() ? 1 : 2,
          speed: objectSpeed + _rand.nextDouble() * (0.15 + 0.12 * level),
        ));
      }
    });
  }

  Future<void> _eggVibration() async {
    final prefs = await SharedPreferences.getInstance();
    final vibroEnabled = prefs.getBool('vibroEnabled') ?? true;
    if (vibroEnabled && (await Vibration.hasVibrator()) == true) {
      Vibration.vibrate(duration: 30);
    }
  }

  void _checkLevelUp() {
    if (level < maxLevel && score >= levelGoals[level - 1]) {
      setState(() {
        level += 1;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        Navigator.pop(context, level);
      });
    }
  }

  void _gameOver() {
    _gameLoop?.cancel();
    setState(() => _gameState = GameState.gameover);
  }

  void _restart() {
    setState(() {
      _gameState = GameState.start;
      chickenX = 0.5;
      chickenY = 0.5;
      score = 0;
      level = widget.initialLevel.clamp(1, levelGoals.length);
      eggs.clear();
      fish.clear();
      bgOffset = 0;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() => _gameState = GameState.playing);
      _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _onTick);
    });
  }

  void _moveLeft() {
    setState(() {
      chickenX -= moveSpeed;
      if (chickenX < 0.08) chickenX = 0.08;
    });
  }

  void _moveRight() {
    setState(() {
      chickenX += moveSpeed;
      if (chickenX > 0.92) chickenX = 0.92;
    });
  }

  void _pauseGame() {
    _gameLoop?.cancel();
    setState(() => _gameState = GameState.paused);
  }

  void _resumeGame() {
    setState(() => _gameState = GameState.playing);
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _onTick);
  }

  @override
  Widget build(BuildContext context) {
    _screenSize ??= MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF201E48),
      body: Stack(
        children: [
          Positioned.fill(child: _MovingBackground(offset: bgOffset)),
          ...eggs.map((egg) => Positioned(
            left: (_screenSize!.width * egg.x) - (_screenSize!.width * egg.size) / 2,
            top: _screenSize!.height * egg.y,
            child: Image.asset('assets/egg.png',
                width: _screenSize!.width * egg.size),
          )),
          ...fish.map((f) => Positioned(
            left: (_screenSize!.width * f.x) - (_screenSize!.width * f.size) / 2,
            top: _screenSize!.height * f.y,
            child: Image.asset(
                f.type == 1 ? 'assets/fish1.png' : 'assets/fish2.png',
                width: _screenSize!.width * f.size),
          )),
          Positioned(
            left: (_screenSize!.width * chickenX) - chickenSize / 2,
            top: (_screenSize!.height * chickenY) - chickenSize / 2,
            child: Image.asset('assets/chicken.png', width: chickenSize, height: chickenSize),
          ),
          // Кнопка паузы (только когда идет игра)
          if (_gameState == GameState.playing)
            Positioned(
              top: 28,
              left: 18,
              child: GestureDetector(
                onTap: _pauseGame,
                child: Image.asset('assets/btn_pause.png', width: 56, height: 56),
              ),
            ),
          if (_gameState == GameState.start)
            const _StartScreen(),
          if (_gameState == GameState.playing)
            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _LevelBar(level: level, maxLevel: maxLevel, score: score, goal: levelGoals[level - 1]),
                  const SizedBox(height: 8),
                  _ScoreBar(score: score),
                ],
              ),
            ),
          if (_gameState == GameState.playing)
            Positioned(
              left: 16,
              bottom: 36,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: _moveLeft,
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Image.asset('assets/btn_right.png', width: 64, height: 64),
                ),
              ),
            ),
          if (_gameState == GameState.playing)
            Positioned(
              right: 16,
              bottom: 36,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: _moveRight,
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Image.asset('assets/btn_left.png', width: 64, height: 64),
                ),
              ),
            ),
          if (_gameState == GameState.gameover)
            _TryNowScreen(onRestart: _restart),
          if (_gameState == GameState.paused)
            _PauseOverlay(
              onBackToMenu: () {
                Navigator.of(context).pop();
              },
              onResume: _resumeGame,
            ),
        ],
      ),
    );
  }
}

class _StartScreen extends StatelessWidget {
  const _StartScreen();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.1),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/chicken.png', width: 110),
              const SizedBox(height: 40),
              Text(
                "READY?",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.yellow.shade300,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  final int level;
  final int maxLevel;
  final int score;
  final int goal;

  const _LevelBar({required this.level, required this.maxLevel, required this.score, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = (score / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        Text(
          "Level $level / $maxLevel",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.yellow.shade300,
            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 180,
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade700,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;
  const _ScoreBar({required this.score});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/egg.png', width: 32),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Text(
            "$score",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
        ),
      ],
    );
  }
}

// ============= GAME OVER SCREEN =============

class _TryNowScreen extends StatelessWidget {
  final VoidCallback onRestart;
  const _TryNowScreen({required this.onRestart});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/try_now.png', width: 330),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/gameover_box.png',
                    width: 350,
                    height: 240,
                    fit: BoxFit.fill,
                  ),
                  Positioned(
                    bottom: 28,
                    left: 30,
                    right: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Image.asset(
                            'assets/btn_back_menu.png',
                            width: 120,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                        GestureDetector(
                          onTap: onRestart,
                          child: Image.asset(
                            'assets/btn_start_again.png',
                            width: 120,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= PAUSE OVERLAY =============

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onBackToMenu;
  final VoidCallback onResume;
  const _PauseOverlay({required this.onBackToMenu, required this.onResume});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Image.asset('assets/gameover_box.png', width: 340, height: 440, fit: BoxFit.fill),
              Padding(
                padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/how_to_play.png', width: 210),
                    const SizedBox(height: 14),
                    const _GameRules(),
                    const Spacer(),
                    GestureDetector(
                      onTap: onBackToMenu,
                      child: Image.asset('assets/btn_back_menu.png', width: 160),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.all(16),
                        elevation: 0,
                      ),
                      onPressed: onResume,
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 34),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= GAME RULES (HOW TO PLAY) =============

class _GameRules extends StatelessWidget {
  const _GameRules();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('COLLECT COINS FOR POINTS', style: _ruleStyle),
        const SizedBox(height: 6),
        Image.asset('assets/egg.png', width: 38),
        const SizedBox(height: 8),
        Text('AVOID THESE CREATURES', style: _ruleStyle),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/fish1.png', width: 36),
            const SizedBox(width: 4),
            Image.asset('assets/fish2.png', width: 36),
            // Добавь другие рыбы если есть
          ],
        ),
      ],
    );
  }
}

const TextStyle _ruleStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w600,
  fontSize: 16,
  shadows: [Shadow(color: Colors.black, blurRadius: 3)],
);

// ============= DATA MODELS & BG =============

class Egg {
  double x, y, size;
  Egg({required this.x, required this.y, required this.size});
}

class Fish {
  double x, y, size, speed;
  int type;
  Fish({required this.x, required this.y, required this.size, required this.type, required this.speed});
}

class _MovingBackground extends StatelessWidget {
  final double offset;
  const _MovingBackground({required this.offset});
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Positioned(
          top: height - offset,
          left: 0,
          right: 0,
          child: Image.asset('assets/bg.png', fit: BoxFit.cover, height: height),
        ),
        Positioned(
          top: -offset,
          left: 0,
          right: 0,
          child: Image.asset('assets/bg.png', fit: BoxFit.cover, height: height),
        ),
      ],
    );
  }
}