import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'player.dart';

enum CatState { sleeping, idle, walk }

class Cat extends SpriteAnimationGroupComponent<CatState>
    with HasGameRef {
  static const double frameWidth = 32;
  static const double frameHeight = 32;
  static const double followSpeed = 60;
  static const double followDistance = 24;
  static const double interactDistance = 20;

  Cat({required Vector2 position})
      : super(
          size: Vector2(32, 32),
          anchor: Anchor.center,
          position: position,
        );

  bool isFollowing = false;
  bool playerNearby = false;

  late SpriteAnimation _sleeping;
  late SpriteAnimation _idle;
  late SpriteAnimation _walkDown;
  late SpriteAnimation _walkUp;
  late SpriteAnimation _walkRight;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAnimations();

    animations = {
      CatState.sleeping: _sleeping,
      CatState.idle: _idle,
      CatState.walk: _walkDown,
    };

    current = isFollowing ? CatState.idle : CatState.sleeping;
  }

  Future<void> _loadAnimations() async {
    final data = await rootBundle.load('assets/tilesets/cat.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final spriteSheet = frame.image;

    SpriteAnimation anim(
      int row,
      int frameCount, {
      double stepTime = 0.15,
      bool loop = true,
    }) {
      return SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: frameCount,
          amountPerRow: frameCount,
          stepTime: stepTime,
          textureSize: Vector2(frameWidth, frameHeight),
          texturePosition: Vector2(0, row * frameHeight),
          loop: loop,
        ),
      );
    }

    _sleeping = anim(7, 2, stepTime: 3.0);
    _idle     = anim(5, 4, stepTime: 0.8);
    _walkDown  = anim(4, 4);
    _walkRight = anim(1, 4);
    _walkUp    = anim(2, 4);
  }

  // toggle follow on/off
  void interact() {
    isFollowing = !isFollowing;
    current = isFollowing ? CatState.idle : CatState.sleeping;
  }

  @override
  void update(double dt) {
    super.update(dt);

    priority = 1000 + position.y.toInt();

    // check if player is nearby for the prompt
    final player = parent?.children.whereType<Player>().firstOrNull;
    if (player != null) {
      playerNearby = absoluteCenter.distanceTo(
            player.absoluteCenter,
          ) <=
          interactDistance;
    } else {
      playerNearby = false;
    }

    if (!isFollowing || player == null) return;

    final toPlayer = player.absoluteCenter - absoluteCenter;
    final distance = toPlayer.length;

    if (distance <= followDistance) {
      current = CatState.idle;
      return;
    }

    final direction = toPlayer.normalized();

    final SpriteAnimation walkAnim;
    if (direction.x.abs() > direction.y.abs()) {
      scale.x = direction.x < 0 ? -1 : 1;
      walkAnim = _walkRight;
    } else if (direction.y < 0) {
      scale.x = 1;
      walkAnim = _walkUp;
    } else {
      scale.x = 1;
      walkAnim = _walkDown;
    }

    if (current != CatState.walk ||
        !identical(animations![CatState.walk], walkAnim)) {
      animations = {
        CatState.sleeping: _sleeping,
        CatState.idle: _idle,
        CatState.walk: walkAnim,
      };
      current = CatState.walk;
    }

    position += direction * followSpeed * dt;
  }

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

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(promptRect, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRRect(promptRect, borderPaint);

    // show E when sleeping, show X when following
    final label = isFollowing ? 'X' : 'X';

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
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
        -promptHeight - 2 + (promptHeight - textPainter.height) / 2,
      ),
    );
  }
}