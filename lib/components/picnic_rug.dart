import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'interactable.dart';
import 'player.dart';

class PicnicRug extends Interactable {
  PicnicRug({
    required Vector2 position,
    required Player player,
  }) : super(
          position: position,
          size: Vector2(32, 20),
          itemId: 'picnic_rug',
          player: player,
          cooldown: 0,
        );

  @override
  void render(Canvas canvas) {
    _drawRug(canvas);

    // The collectible rug displays the Z prompt.
    super.render(canvas);
  }

  void _drawRug(Canvas canvas) {
    // ------------------------------------------------------------
    // Rug body
    // ------------------------------------------------------------

    final rugRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        1,
        1,
        size.x - 2,
        size.y - 2,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(
      rugRect,
      Paint()
        ..color = const Color(0xFFFFB702)
        ..style = PaintingStyle.fill,
    );

    // ------------------------------------------------------------
    // Border
    // ------------------------------------------------------------

    canvas.drawRRect(
      rugRect,
      Paint()
        ..color = const Color(0xFF8B6F47)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ------------------------------------------------------------
    // Woven stripes
    // ------------------------------------------------------------

    final stripePaint = Paint()
      ..color = const Color(0xFFB49A68)
      ..strokeWidth = 1;

    for (double x = 5; x < size.x - 3; x += 5) {
      canvas.drawLine(
        Offset(x, 3),
        Offset(x, size.y - 3),
        stripePaint,
      );
    }

    // ------------------------------------------------------------
    // Fringe
    // ------------------------------------------------------------

    final fringePaint = Paint()
      ..color = const Color(0xFFE8D5A3)
      ..strokeWidth = 1;

    for (double y = 3; y < size.y - 2; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(2, y),
        fringePaint,
      );

      canvas.drawLine(
        Offset(size.x - 2, y),
        Offset(size.x, y),
        fringePaint,
      );
    }
  }
}

// ===========================================================================
// PLACED PICNIC RUG
// ===========================================================================
//
// This is only visual decoration.
// It is NOT an Interactable, so the player cannot accidentally interact
// with it after placing the rug.
// ===========================================================================

class PlacedPicnicRug extends PositionComponent {
  PlacedPicnicRug({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(32, 20),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    // ------------------------------------------------------------
    // Rug body
    // ------------------------------------------------------------

    final rugRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        1,
        1,
        size.x - 2,
        size.y - 2,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(
      rugRect,
      Paint()
        ..color = const Color(0xFFFFB702)
        ..style = PaintingStyle.fill,
    );

    // ------------------------------------------------------------
    // Border
    // ------------------------------------------------------------

    canvas.drawRRect(
      rugRect,
      Paint()
        ..color = const Color(0xFF8B6F47)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ------------------------------------------------------------
    // Woven stripes
    // ------------------------------------------------------------

    final stripePaint = Paint()
      ..color = const Color(0xFFB49A68)
      ..strokeWidth = 1;

    for (double x = 5; x < size.x - 3; x += 5) {
      canvas.drawLine(
        Offset(x, 3),
        Offset(x, size.y - 3),
        stripePaint,
      );
    }

    // ------------------------------------------------------------
    // Fringe
    // ------------------------------------------------------------

    final fringePaint = Paint()
      ..color = const Color(0xFFE8D5A3)
      ..strokeWidth = 1;

    for (double y = 3; y < size.y - 2; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(2, y),
        fringePaint,
      );

      canvas.drawLine(
        Offset(size.x - 2, y),
        Offset(size.x, y),
        fringePaint,
      );
    }
  }
}