import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game.dart';
import 'player.dart';

class DressPickup extends PositionComponent with HasGameRef {
  DressPickup({required Vector2 position})
      : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2(24, 44), // display size in game units
        );

  static const double interactDistance = 20;

  ui.Image? _image;
  bool _collected = false;
  bool playerNearby = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final data = await rootBundle.load('assets/tilesets/dress.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _image = frame.image;

    priority = 1000 + position.y.toInt();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_collected) return;

    final player = parent?.children
        .whereType<Player>()
        .firstOrNull;

    playerNearby = player != null &&
        absoluteCenter.distanceTo(player.absoluteCenter) <=
            interactDistance;
  }

  void interact() {
    if (!playerNearby || _collected) return;

    _collected = true;

    final game = findGame()! as BeachHouseGame;
    game.inventory.add('present');

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_collected || _image == null) return;

    // draw the dress sprite scaled to component size
    final src = Rect.fromLTWH(
      0,
      0,
      _image!.width.toDouble(),
      _image!.height.toDouble(),
    );

    final dst = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawImageRect(_image!, src, dst, Paint());

    // E prompt when nearby
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

    canvas.drawRRect(
      promptRect,
      Paint()
        ..color = Colors.black.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      promptRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Z',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        size.x / 2 - textPainter.width / 2,
        -promptHeight - 2 + (promptHeight - textPainter.height) / 2,
      ),
    );
  }
}