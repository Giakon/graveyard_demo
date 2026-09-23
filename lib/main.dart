import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'ui/hotbar.dart';
import 'widgets/task_list.dart';
import 'mobile_input.dart';
import 'components/player.dart';

void main() {
  final game = BeachHouseGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _GameScreen(game: game),
      ),
    ),
  );
}

class _GameScreen extends StatefulWidget {
  const _GameScreen({required this.game});

  final BeachHouseGame game;

  @override
  State<_GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<_GameScreen> {
  bool get _showMobileControls {
    if (!kIsWeb) {
      return true;
    }

    final view = WidgetsBinding.instance.platformDispatcher.views.first;

    final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
    final logicalHeight = view.physicalSize.height / view.devicePixelRatio;

    return logicalWidth < 700 || logicalHeight < 600;
  }

  void _startGame() {
    if (!widget.game.gameStarted) {
      setState(() {
        widget.game.gameStarted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyF) {
          if (!widget.game.gameStarted) {
            _startGame();
          }
        }

        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.game.dismissThoughts,
        child: Stack(
          children: [
          // =================================================================
          // GAME
          // =================================================================

          GameWidget(
            game: widget.game,
            autofocus: true,
            overlayBuilderMap: {
              'hotbar': (context, g) {
                final game = g as BeachHouseGame;

                return ExcludeFocus(
                  child: Hotbar(
                    inventory: game.inventory,
                  ),
                );
              },

              'itemPickup': (context, g) {
                return const ExcludeFocus(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: _PickupNotification(),
                    ),
                  ),
                );
              },

              'tasks': (context, g) {
                return const ExcludeFocus(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                        right: 20,
                      ),
                      child: TaskList(),
                    ),
                  ),
                );
              },
            },
            initialActiveOverlays: const [
              'hotbar',
              'tasks',
            ],
          ),

          // =================================================================
          // MOBILE CONTROLS
          // =================================================================

          if (_showMobileControls && widget.game.gameStarted)
  Positioned.fill(
    child: _MobileControls(
      game: widget.game,
    ),
  ),

          // =================================================================
          // START SCREEN
          // =================================================================

          if (!widget.game.gameStarted)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _startGame,
                child: const _StartScreen(),
              ),
            ),

          // =================================================================
          // ENDING
          // =================================================================

          ValueListenableBuilder<bool>(
            valueListenable: widget.game.showEnding,
            builder: (context, showEnding, child) {
              if (!showEnding) {
                return const SizedBox.shrink();
              }

              return const Positioned.fill(
                child: _EndingScreen(),
              );
            },
          ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// MOBILE CONTROLS
// ===========================================================================
// ===========================================================================
// MOBILE CONTROLS
// ===========================================================================
class _MobileControls extends StatelessWidget {
  const _MobileControls({
    required this.game,
  });

  final BeachHouseGame game;

  Player? _getPlayer() {
    Player? findPlayer(Component component) {
      if (component is Player) {
        return component;
      }

      for (final child in component.children) {
        final player = findPlayer(child);
        if (player != null) {
          return player;
        }
      }

      return null;
    }

    for (final child in game.children) {
      final player = findPlayer(child);
      if (player != null) {
        return player;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // =================================================================
          // D-PAD
          // =================================================================

          Positioned(
            left: 20,
            bottom: 108,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                children: [
                  // UP
                  Positioned(
                    left: 50,
                    top: 0,
                    child: _DirectionButton(
                      icon: Icons.keyboard_arrow_up,
                      onPressed: () {
                        MobileInput.up = true;
                      },
                      onReleased: () {
                        MobileInput.up = false;
                      },
                    ),
                  ),

                  // LEFT
                  Positioned(
                    left: 0,
                    top: 50,
                    child: _DirectionButton(
                      icon: Icons.keyboard_arrow_left,
                      onPressed: () {
                        MobileInput.left = true;
                      },
                      onReleased: () {
                        MobileInput.left = false;
                      },
                    ),
                  ),

                  // RIGHT
                  Positioned(
                    right: 0,
                    top: 50,
                    child: _DirectionButton(
                      icon: Icons.keyboard_arrow_right,
                      onPressed: () {
                        MobileInput.right = true;
                      },
                      onReleased: () {
                        MobileInput.right = false;
                      },
                    ),
                  ),

                  // DOWN
                  Positioned(
                    left: 50,
                    bottom: 0,
                    child: _DirectionButton(
                      icon: Icons.keyboard_arrow_down,
                      onPressed: () {
                        MobileInput.down = true;
                      },
                      onReleased: () {
                        MobileInput.down = false;
                      },
                    ),
                  ),

                  // CENTER
                  Positioned(
                    left: 50,
                    top: 50,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =================================================================
          // ACTION BUTTONS
          // =================================================================

          Positioned(
            right: 22,
            bottom: 112,
            child: SizedBox(
              width: 170,
              height: 150,
              child: Stack(
                children: [
                  // X - CAT
                  Positioned(
                    right: 0,
                    top: 48,
                    child: _ActionButton(
                      label: 'X',
                      color: const Color(0xFFB85C6A),
                      onPressed: () {
                        _getPlayer()?.touchCat();
                      },
                    ),
                  ),

                  // Z - ACTION
                  Positioned(
                    right: 62,
                    top: 0,
                    child: _ActionButton(
                      label: 'Z',
                      color: const Color(0xFF8E6570),
                      onPressed: () {
                        _getPlayer()?.touchAction();
                      },
                    ),
                  ),

                  // E - INTERACT
                  Positioned(
                    right: 62,
                    bottom: 0,
                    child: _ActionButton(
                      label: 'E',
                      color: const Color(0xFF657B8E),
                      onPressed: () {
                        _getPlayer()?.touchInteract();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ===========================================================================
// DIRECTION BUTTON
// ===========================================================================

class _DirectionButton extends StatefulWidget {
  const _DirectionButton({
    required this.icon,
    required this.onPressed,
    required this.onReleased,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  @override
  State<_DirectionButton> createState() => _DirectionButtonState();
}

class _DirectionButtonState extends State<_DirectionButton> {
  bool _pressed = false;

  void _press() {
    if (_pressed) {
      return;
    }

    setState(() {
      _pressed = true;
    });

    widget.onPressed();
  }

  void _release() {
    if (!_pressed) {
      return;
    }

    setState(() {
      _pressed = false;
    });

    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.35)
              : Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
          ),
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

// ===========================================================================
// ACTION BUTTON
// ===========================================================================

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  void _press() {
    if (_pressed) {
      return;
    }

    setState(() {
      _pressed = true;
    });

    widget.onPressed();
  }

  void _release() {
    if (!_pressed) {
      return;
    }

    setState(() {
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.95)
              : widget.color.withOpacity(0.75),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// START SCREEN
// ===========================================================================

class _StartScreen extends StatefulWidget {
  const _StartScreen();

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF151116),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    const Color(0xFF3B2932).withOpacity(0.8),
                    const Color(0xFF151116),
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final t = _animationController.value;

              return Stack(
                children: [
                  _heart(
                    left: 55,
                    bottom: 38 + (t * 25),
                    size: 8,
                    opacity: 0.35,
                  ),
                  _heart(
                    left: 92,
                    bottom: 42 + (((t + 0.3) % 1) * 30),
                    size: 5,
                    opacity: 0.25,
                  ),
                  _heart(
                    right: 60,
                    bottom: 40 + (((t + 0.6) % 1) * 28),
                    size: 7,
                    opacity: 0.30,
                  ),
                  _heart(
                    right: 100,
                    bottom: 55 + (((t + 0.15) % 1) * 25),
                    size: 4,
                    opacity: 0.20,
                  ),
                ],
              );
            },
          ),

          Center(
            child: Container(
              width: 250,
              padding: const EdgeInsets.fromLTRB(
                28,
                24,
                28,
                22,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1DFC0),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: const Color(0xFFC5A978),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '♥',
                    style: TextStyle(
                      color: Color(0xFFB85C6A),
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'A little something',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF69564A),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: 80,
                    height: 1,
                    color: const Color(0xFFBBA27D),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Made as a token\nof my love to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4D4038),
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'serif',
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Afet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9D4F5E),
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'serif',
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: 80,
                    height: 1,
                    color: const Color(0xFFBBA27D),
                  ),

                  const SizedBox(height: 18),

                  FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.45,
                      end: 1.0,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: const Text(
                      'Tap anywhere to begin',
                      style: TextStyle(
                        color: Color(0xFF604C40),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  
                ],
              ),
            ),
          ),

          const Positioned(
            top: 18,
            left: 18,
            child: _PixelCorner(),
          ),

          const Positioned(
            top: 18,
            right: 18,
            child: RotatedBox(
              quarterTurns: 1,
              child: _PixelCorner(),
            ),
          ),

          const Positioned(
            bottom: 18,
            left: 18,
            child: RotatedBox(
              quarterTurns: 3,
              child: _PixelCorner(),
            ),
          ),

          const Positioned(
            bottom: 18,
            right: 18,
            child: RotatedBox(
              quarterTurns: 2,
              child: _PixelCorner(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heart({
    double? left,
    double? right,
    required double bottom,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: Opacity(
        opacity: opacity,
        child: Text(
          '♥',
          style: TextStyle(
            color: const Color(0xFFE08A99),
            fontSize: size,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ENDING SCREEN
// ===========================================================================

class _EndingScreen extends StatefulWidget {
  const _EndingScreen();

  @override
  State<_EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<_EndingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        final sceneOpacity = Curves.easeInOut.transform(
          (value / 0.18).clamp(0.0, 1.0),
        );

        final textOpacity = Curves.easeOut.transform(
          ((value - 0.35) / 0.25).clamp(0.0, 1.0),
        );

        final textOffset = 18.0 * (1.0 - textOpacity);

        return Opacity(
          opacity: sceneOpacity,
          child: Container(
            color: const Color(0xFFF4DCCF),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EndingScenePainter(
                      progress: value,
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 30,
                        right: 30,
                        bottom: 30,
                      ),
                      child: Opacity(
                        opacity: textOpacity,
                        child: Transform.translate(
                          offset: Offset(0, textOffset),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'And now, all that is left...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF654C4C),
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'serif',
                                ),
                              ),

                              SizedBox(height: 7),

                              Text(
                                'is to wake you up',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF4F3C3C),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'serif',
                                ),
                              ),

                              SizedBox(height: 7),

                              Text(
                                'and make this day as special as you are.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF654C4C),
                                  fontSize: 12,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'serif',
                                ),
                              ),

                              SizedBox(height: 13),

                              Text(
                                'I love you, Afet. ♥',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9D4F5E),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'serif',
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// ENDING SCENE PAINTER
// ===========================================================================

class _EndingScenePainter extends CustomPainter {
  const _EndingScenePainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ========================================================================
    // SKY
    // ========================================================================

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF655464),
            Color(0xFF9C7075),
            Color(0xFFD8958D),
            Color(0xFFF1C19E),
            Color(0xFFF4DCC5),
          ],
        ).createShader(
          Rect.fromLTWH(0, 0, w, h),
        ),
    );

    // ========================================================================
    // SUN
    // ========================================================================

    final sunY = h * 0.39;

    canvas.drawCircle(
      Offset(w / 2, sunY),
      27,
      Paint()..color = const Color(0xFFFFE0A5),
    );

    canvas.drawCircle(
      Offset(w / 2, sunY),
      70,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE4B0).withOpacity(0.35),
            const Color(0xFFFFE4B0).withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(w / 2, sunY),
            radius: 70,
          ),
        ),
    );

    // ========================================================================
    // SEA
    // ========================================================================

    final seaTop = h * 0.44;

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        seaTop,
        w,
        h * 0.28,
      ),
      Paint()..color = const Color(0xFF5F8793),
    );

    // ========================================================================
    // WAVES
    // ========================================================================

    final wavePaint = Paint()
      ..color = const Color(0xFFA9C5C5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var y = seaTop + 12; y < seaTop + 82; y += 14) {
      for (var x = -20.0; x < w + 20; x += 38) {
        final path = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(
            x + 9,
            y - 4,
            x + 19,
            y,
          )
          ..quadraticBezierTo(
            x + 29,
            y + 4,
            x + 38,
            y,
          );

        canvas.drawPath(
          path,
          wavePaint,
        );
      }
    }

    // ========================================================================
    // DISTANT SHORELINE
    // ========================================================================

    final distantPath = Path()
      ..moveTo(0, h * 0.70)
      ..lineTo(w * 0.13, h * 0.67)
      ..lineTo(w * 0.27, h * 0.70)
      ..lineTo(w * 0.40, h * 0.675)
      ..lineTo(w * 0.55, h * 0.70)
      ..lineTo(w * 0.70, h * 0.665)
      ..lineTo(w * 0.84, h * 0.695)
      ..lineTo(w, h * 0.665)
      ..lineTo(w, h * 0.73)
      ..lineTo(0, h * 0.73)
      ..close();

    canvas.drawPath(
      distantPath,
      Paint()..color = const Color(0xFF46545A),
    );

    // ========================================================================
    // SAND
    // ========================================================================

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        h * 0.70,
        w,
        h * 0.30,
      ),
      Paint()..color = const Color(0xFFEBCB9E),
    );

    // ========================================================================
    // BEACH DETAILS
    // ========================================================================

    final grassPaint = Paint()
      ..color = const Color(0xFF9C8869)
      ..strokeWidth = 1;

    for (var x = 8.0; x < w; x += 27) {
      final y = h * 0.73 + ((x * 13) % 17);

      canvas.drawLine(
        Offset(x, y),
        Offset(x + 2, y - 5),
        grassPaint,
      );

      canvas.drawLine(
        Offset(x + 3, y),
        Offset(x + 6, y - 4),
        grassPaint,
      );
    }

    // ========================================================================
    // PICNIC RUG
    // ========================================================================

    final rugCenter = Offset(
      w / 2,
      h * 0.785,
    );

    const rugWidth = 150.0;
    const rugHeight = 65.0;

    final rugRect = Rect.fromCenter(
      center: rugCenter,
      width: rugWidth,
      height: rugHeight,
    );

    final rug = RRect.fromRectAndRadius(
      rugRect,
      const Radius.circular(5),
    );

    canvas.drawRRect(
      rug,
      Paint()..color = const Color(0xFFD79B68),
    );

    final stripePaint = Paint()
      ..color = const Color(0xFFF1C18B)
      ..strokeWidth = 3;

    for (
      var x = rugCenter.dx - 64;
      x < rugCenter.dx + 64;
      x += 16
    ) {
      canvas.drawLine(
        Offset(x, rugCenter.dy - 29),
        Offset(x, rugCenter.dy + 29),
        stripePaint,
      );
    }

    canvas.drawRRect(
      rug,
      Paint()
        ..color = const Color(0xFF93634E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ========================================================================
    // COUPLE
    // ========================================================================

    final gentleMovement = (progress * 6).clamp(
      0.0,
      6.0,
    );

    final coupleY = h * 0.715 - gentleMovement;

    _drawCouple(
      canvas,
      center: Offset(
        w / 2,
        coupleY,
      ),
    );

    _drawEndingCat(
      canvas,
      center: Offset(
        w / 2 + 70,
        coupleY + 18,
      ),
    );

    // ========================================================================
    // HEARTS
    // ========================================================================

    final heartProgress = ((progress - 0.45) / 0.25).clamp(
      0.0,
      1.0,
    );

    if (heartProgress > 0) {
      _drawHeart(
        canvas,
        Offset(
          w / 2,
          coupleY - 45 - heartProgress * 16,
        ),
        7,
        heartProgress,
      );

      _drawHeart(
        canvas,
        Offset(
          w / 2 - 23,
          coupleY - 38 - heartProgress * 30,
        ),
        4,
        heartProgress * 0.7,
      );

      _drawHeart(
        canvas,
        Offset(
          w / 2 + 24,
          coupleY - 35 - heartProgress * 40,
        ),
        4,
        heartProgress * 0.6,
      );
    }
  }

  // =========================================================================
  // CAT
  // =========================================================================

  void _drawEndingCat(
    Canvas canvas, {
    required Offset center,
  }) {
    const fur = Color(0xFFD9823B);
    const furLight = Color(0xFFEAA45F);
    const stripe = Color(0xFF9B5428);
    const dark = Color(0xFF4A3028);
    const eye = Color(0xFF3A2924);

    final cx = center.dx;
    final cy = center.dy;

    // ========================================================================
    // TAIL
    // ========================================================================

    final tailPaint = Paint()
      ..color = fur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final tail = Path()
      ..moveTo(
        cx + 13,
        cy + 9,
      )
      ..quadraticBezierTo(
        cx + 28,
        cy + 16,
        cx + 27,
        cy + 3,
      )
      ..quadraticBezierTo(
        cx + 26,
        cy - 4,
        cx + 31,
        cy - 7,
      );

    canvas.drawPath(
      tail,
      tailPaint,
    );

    final tailStripePaint = Paint()
      ..color = stripe
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx + 22, cy + 11),
      Offset(cx + 24, cy + 7),
      tailStripePaint,
    );

    canvas.drawLine(
      Offset(cx + 26, cy + 8),
      Offset(cx + 28, cy + 4),
      tailStripePaint,
    );

    // ========================================================================
    // BODY
    // ========================================================================

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 7),
        width: 27,
        height: 20,
      ),
      Paint()..color = fur,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 2, cy + 9),
        width: 14,
        height: 12,
      ),
      Paint()..color = furLight,
    );

    // ========================================================================
    // BACK STRIPES
    // ========================================================================

    final bodyStripePaint = Paint()
      ..color = stripe
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 8, cy - 1),
      Offset(cx - 5, cy + 5),
      bodyStripePaint,
    );

    canvas.drawLine(
      Offset(cx - 3, cy - 3),
      Offset(cx, cy + 4),
      bodyStripePaint,
    );

    canvas.drawLine(
      Offset(cx + 3, cy - 3),
      Offset(cx + 6, cy + 4),
      bodyStripePaint,
    );

    // ========================================================================
    // LEGS
    // ========================================================================

    final legPaint = Paint()
      ..color = fur
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 8, cy + 13),
      Offset(cx - 9, cy + 20),
      legPaint,
    );

    canvas.drawLine(
      Offset(cx + 7, cy + 13),
      Offset(cx + 8, cy + 20),
      legPaint,
    );

    canvas.drawLine(
      Offset(cx - 11, cy + 20),
      Offset(cx - 7, cy + 20),
      legPaint,
    );

    canvas.drawLine(
      Offset(cx + 6, cy + 20),
      Offset(cx + 10, cy + 20),
      legPaint,
    );

    // ========================================================================
    // HEAD
    // ========================================================================

    final headCenter = Offset(
      cx - 11,
      cy - 7,
    );

    canvas.drawCircle(
      headCenter,
      10,
      Paint()..color = fur,
    );

    // ========================================================================
    // EARS
    // ========================================================================

    final leftEar = Path()
      ..moveTo(
        cx - 19,
        cy - 13,
      )
      ..lineTo(
        cx - 20,
        cy - 25,
      )
      ..lineTo(
        cx - 11,
        cy - 18,
      )
      ..close();

    canvas.drawPath(
      leftEar,
      Paint()..color = fur,
    );

    final rightEar = Path()
      ..moveTo(
        cx - 10,
        cy - 18,
      )
      ..lineTo(
        cx - 4,
        cy - 25,
      )
      ..lineTo(
        cx - 3,
        cy - 13,
      )
      ..close();

    canvas.drawPath(
      rightEar,
      Paint()..color = fur,
    );

    final innerEarPaint = Paint()
      ..color = const Color(0xFFF1A078);

    final innerLeft = Path()
      ..moveTo(cx - 18, cy - 16)
      ..lineTo(cx - 18, cy - 21)
      ..lineTo(cx - 13, cy - 17)
      ..close();

    canvas.drawPath(
      innerLeft,
      innerEarPaint,
    );

    final innerRight = Path()
      ..moveTo(cx - 9, cy - 17)
      ..lineTo(cx - 5, cy - 21)
      ..lineTo(cx - 5, cy - 16)
      ..close();

    canvas.drawPath(
      innerRight,
      innerEarPaint,
    );

    // ========================================================================
    // FACE
    // ========================================================================

    canvas.drawCircle(
      Offset(cx - 15, cy - 8),
      1.5,
      Paint()..color = eye,
    );

    canvas.drawCircle(
      Offset(cx - 7, cy - 8),
      1.5,
      Paint()..color = eye,
    );

    final nose = Path()
      ..moveTo(cx - 12, cy - 4)
      ..lineTo(cx - 10, cy - 4)
      ..lineTo(cx - 11, cy - 2)
      ..close();

    canvas.drawPath(
      nose,
      Paint()..color = const Color(0xFF8C4A4A),
    );

    // ========================================================================
    // WHISKERS
    // ========================================================================

    final whiskerPaint = Paint()
      ..color = dark
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(cx - 15, cy - 3),
      Offset(cx - 28, cy - 6),
      whiskerPaint,
    );

    canvas.drawLine(
      Offset(cx - 15, cy - 1),
      Offset(cx - 28, cy),
      whiskerPaint,
    );

    canvas.drawLine(
      Offset(cx - 7, cy - 3),
      Offset(cx + 1, cy - 6),
      whiskerPaint,
    );

    // ========================================================================
    // FOREHEAD STRIPES
    // ========================================================================

    canvas.drawLine(
      Offset(cx - 14, cy - 15),
      Offset(cx - 13, cy - 11),
      bodyStripePaint,
    );

    canvas.drawLine(
      Offset(cx - 10, cy - 16),
      Offset(cx - 10, cy - 12),
      bodyStripePaint,
    );

    canvas.drawLine(
      Offset(cx - 6, cy - 15),
      Offset(cx - 7, cy - 11),
      bodyStripePaint,
    );
  }

  // =========================================================================
  // COUPLE
  // =========================================================================

  void _drawCouple(
    Canvas canvas, {
    required Offset center,
  }) {
    const skinL = Color(0xFFE7B38F);
    const skinR = Color(0xFFE9B996);

    const hairL = Color(0xFF553C32);
    const hairR = Color(0xFF3D302C);

    const shirtL = Color(0xFF8E6570);
    const shirtR = Color(0xFFE6B7A5);

    const pantsL = Color(0xFF5A4A6A);
    const pantsR = Color(0xFF4A5A6A);

    final cx = center.dx;
    final cy = center.dy;

    // ========================================================================
    // LEGS
    // ========================================================================

    final legPaintL = Paint()
      ..color = pantsL
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final legPaintR = Paint()
      ..color = pantsR
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 18, cy + 18),
      Offset(cx - 34, cy + 30),
      legPaintL,
    );

    canvas.drawLine(
      Offset(cx - 8, cy + 18),
      Offset(cx - 16, cy + 30),
      legPaintL,
    );

    canvas.drawLine(
      Offset(cx + 8, cy + 18),
      Offset(cx + 16, cy + 30),
      legPaintR,
    );

    canvas.drawLine(
      Offset(cx + 18, cy + 18),
      Offset(cx + 34, cy + 30),
      legPaintR,
    );

    void foot(
      Offset pos,
      Color color,
    ) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: pos,
            width: 12,
            height: 6,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = color,
      );
    }

    foot(
      Offset(cx - 34, cy + 33),
      skinL,
    );

    foot(
      Offset(cx - 16, cy + 33),
      skinL,
    );

    foot(
      Offset(cx + 16, cy + 33),
      skinR,
    );

    foot(
      Offset(cx + 34, cy + 33),
      skinR,
    );

    // ========================================================================
    // BODIES
    // ========================================================================

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 13, cy + 4),
          width: 24,
          height: 26,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = shirtL,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 13, cy + 4),
          width: 24,
          height: 26,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = shirtR,
    );

    // ========================================================================
    // NECKS
    // ========================================================================

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 13, cy - 11),
          width: 8,
          height: 8,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = skinL,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 13, cy - 11),
          width: 8,
          height: 8,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = skinR,
    );

    // ========================================================================
    // HEADS
    // ========================================================================

    final leftHead = Offset(
      cx - 13,
      cy - 22,
    );

    final rightHead = Offset(
      cx + 13,
      cy - 22,
    );

    canvas.save();

    canvas.translate(
      leftHead.dx,
      leftHead.dy,
    );

    canvas.rotate(0.10);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 19,
        height: 21,
      ),
      Paint()..color = skinL,
    );

    canvas.restore();

    canvas.save();

    canvas.translate(
      rightHead.dx,
      rightHead.dy,
    );

    canvas.rotate(-0.10);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 19,
        height: 21,
      ),
      Paint()..color = skinR,
    );

    canvas.restore();

    // ========================================================================
    // LEFT PERSON HAIR
    // ========================================================================

    final longHairPath = Path();

    longHairPath.moveTo(
      cx - 24,
      cy - 25,
    );

    longHairPath.cubicTo(
      cx - 23,
      cy - 36,
      cx - 17,
      cy - 40,
      cx - 10,
      cy - 38,
    );

    longHairPath.cubicTo(
      cx - 3,
      cy - 36,
      cx - 3,
      cy - 29,
      cx - 3,
      cy - 23,
    );

    longHairPath.lineTo(
      cx - 7,
      cy - 15,
    );

    longHairPath.lineTo(
      cx - 9,
      cy - 20,
    );

    longHairPath.lineTo(
      cx - 18,
      cy - 14,
    );

    longHairPath.lineTo(
      cx - 22,
      cy - 7,
    );

    longHairPath.lineTo(
      cx - 25,
      cy - 12,
    );

    longHairPath.lineTo(
      cx - 26,
      cy - 20,
    );

    longHairPath.close();

    canvas.drawPath(
      longHairPath,
      Paint()..color = hairL,
    );

    final longHairStrand = Paint()
      ..color = const Color(0xFF69493D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 22, cy - 25),
      Offset(cx - 23, cy - 10),
      longHairStrand,
    );

    canvas.drawLine(
      Offset(cx - 18, cy - 31),
      Offset(cx - 19, cy - 9),
      longHairStrand,
    );

    canvas.drawLine(
      Offset(cx - 13, cy - 34),
      Offset(cx - 14, cy - 13),
      longHairStrand,
    );

    // ========================================================================
    // RIGHT PERSON HAIR
    // ========================================================================

    final shortHairPath = Path();

    shortHairPath.moveTo(
      cx + 4,
      cy - 25,
    );

    shortHairPath.cubicTo(
      cx + 5,
      cy - 35,
      cx + 11,
      cy - 39,
      cx + 18,
      cy - 37,
    );

    shortHairPath.cubicTo(
      cx + 25,
      cy - 35,
      cx + 27,
      cy - 29,
      cx + 26,
      cy - 22,
    );

    shortHairPath.lineTo(
      cx + 25,
      cy - 14,
    );

    shortHairPath.lineTo(
      cx + 21,
      cy - 11,
    );

    shortHairPath.lineTo(
      cx + 20,
      cy - 18,
    );

    shortHairPath.cubicTo(
      cx + 17,
      cy - 23,
      cx + 12,
      cy - 25,
      cx + 7,
      cy - 22,
    );

    shortHairPath.close();

    canvas.drawPath(
      shortHairPath,
      Paint()..color = hairR,
    );

    final shortHairHighlight = Paint()
      ..color = const Color(0xFF51403A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx + 8, cy - 34),
      Offset(cx + 18, cy - 34),
      shortHairHighlight,
    );

    canvas.drawLine(
      Offset(cx + 23, cy - 31),
      Offset(cx + 24, cy - 21),
      shortHairHighlight,
    );

    // ========================================================================
    // ARMS — HUGGING
    // ========================================================================

    final armPaintL = Paint()
      ..color = shirtL
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 3, cy - 5),
      Offset(cx + 24, cy - 10),
      armPaintL,
    );

    canvas.drawCircle(
      Offset(cx + 24, cy - 10),
      5,
      Paint()..color = skinL,
    );

    final armPaintR = Paint()
      ..color = shirtR
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx + 3, cy),
      Offset(cx - 18, cy - 4),
      armPaintR,
    );

    canvas.drawCircle(
      Offset(cx - 18, cy - 4),
      4,
      Paint()..color = skinR,
    );

    // ========================================================================
    // LITTLE GLOW
    // ========================================================================

    canvas.drawCircle(
      Offset(cx, cy - 24),
      5,
      Paint()
        ..color = const Color(0xFFFFD0C0).withOpacity(0.25),
    );
  }

  // =========================================================================
  // HEART
  // =========================================================================

  void _drawHeart(
    Canvas canvas,
    Offset center,
    double size,
    double opacity,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFB85C6A).withOpacity(opacity);

    final path = Path()
      ..moveTo(
        center.dx,
        center.dy + size,
      )
      ..cubicTo(
        center.dx - size * 1.8,
        center.dy - size * 0.2,
        center.dx - size,
        center.dy - size * 1.5,
        center.dx,
        center.dy - size * 0.5,
      )
      ..cubicTo(
        center.dx + size,
        center.dy - size * 1.5,
        center.dx + size * 1.8,
        center.dy - size * 0.2,
        center.dx,
        center.dy + size,
      );

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _EndingScenePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ===========================================================================
// PIXEL CORNER
// ===========================================================================

class _PixelCorner extends StatelessWidget {
  const _PixelCorner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _PixelCornerPainter(),
      ),
    );
  }
}

class _PixelCornerPainter extends CustomPainter {
  const _PixelCornerPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF5D4A53)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 3, 3),
      paint,
    );

    canvas.drawRect(
      const Rect.fromLTWH(6, 0, 3, 3),
      paint,
    );

    canvas.drawRect(
      const Rect.fromLTWH(12, 0, 3, 3),
      paint,
    );

    canvas.drawRect(
      const Rect.fromLTWH(0, 6, 3, 3),
      paint,
    );

    canvas.drawRect(
      const Rect.fromLTWH(0, 12, 3, 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ===========================================================================
// PICKUP NOTIFICATION
// ===========================================================================

class _PickupNotification extends StatelessWidget {
  const _PickupNotification();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '+ Item collected',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}