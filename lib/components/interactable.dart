import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'player.dart';

class Interactable extends PositionComponent {
  Interactable({
    required Vector2 position,
    required Vector2 size,
    required this.itemId,
    required PositionComponent player,
    this.cooldown = 5.0,
    this.onInteract,
  }) : _player = player,
       super(
         position: position,
         size: size,
       );

  final String itemId;
  final PositionComponent _player;
  final double cooldown;

  /// Called when the player successfully interacts.
  final VoidCallback? onInteract;

  bool playerNearby = false;
  bool onCooldown = false;

  double _cooldownTimer = 0;
  double _cooldownTotal = 0;

  static const double interactionDistance = 24;

  void interact() {
    if (!playerNearby || onCooldown) return;

    onCooldown = true;
    _cooldownTimer = cooldown;
    _cooldownTotal = cooldown;

    onInteract?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (onCooldown) {
      _cooldownTimer -= dt;

      if (_cooldownTimer <= 0) {
        onCooldown = false;
        _cooldownTimer = 0;
      }
    }

    final player =
        parent?.children.whereType<Player>().firstOrNull;

    playerNearby = player != null &&
        absoluteCenter.distanceTo(player.absoluteCenter) <=
            interactionDistance;
  }

  double get cooldownProgress =>
      onCooldown ? _cooldownTimer / _cooldownTotal : 0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!playerNearby) return;

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

    final bgColor = onCooldown
        ? Colors.grey.withOpacity(0.9)
        : Colors.black.withOpacity(0.9);

    canvas.drawRRect(
      promptRect,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      promptRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    if (onCooldown) {
      final center = Offset(
        size.x / 2,
        -promptHeight / 2 - 2,
      );

      canvas.drawArc(
        Rect.fromCenter(
          center: center,
          width: promptWidth,
          height: promptHeight,
        ),
        -3.14 / 2,
        3.14 * 2 * (1 - cooldownProgress),
        true,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: onCooldown ? '...' : 'Z',
        style: TextStyle(
          color: onCooldown
              ? Colors.grey[300]
              : Colors.white,
          fontSize: onCooldown ? 6 : 8,
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
}