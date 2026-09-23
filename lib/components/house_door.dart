import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game.dart';

class HouseDoor extends PositionComponent {
  HouseDoor({
    required Vector2 position,
    required Vector2 size,
    required PositionComponent player,
    this.destinationRoute = 'first_floor',
  })  : _player = player,
        super(
          position: position,
          size: size,
          priority: 200000,
        );

  final PositionComponent _player;

  /// Route to open when the player presses E.
  final String destinationRoute;

  bool playerNearby = false;

  static const double interactionDistance = 30;

  @override
  void update(double dt) {
    super.update(dt);

    final doorCenter = absoluteCenter;
    final playerCenter = _player.absoluteCenter;

    playerNearby =
        doorCenter.distanceTo(playerCenter) <= interactionDistance;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!playerNearby) {
      return;
    }

    const double promptWidth = 12;
    const double promptHeight = 12;

    final promptRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.x / 2 - promptWidth / 2,
        -promptHeight - 2,
        promptWidth,
        promptHeight,
      ),
      const Radius.circular(1),
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(promptRect, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRRect(promptRect, borderPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'E',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        size.x / 2 - textPainter.width / 2,
        -promptHeight -
            2 +
            (promptHeight - textPainter.height) / 2,
      ),
    );
  }

  void interact() {
    if (!playerNearby) {
      return;
    }

    final game = findGame() as BeachHouseGame;

    game.router.pushNamed(destinationRoute);
  }
}