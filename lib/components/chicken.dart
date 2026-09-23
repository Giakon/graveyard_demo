import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'collision_block.dart';

enum ChickenState {
  idle,
  walk,
  happy,
}

enum ChickenDirection {
  left,
  right,
}

class Chicken extends SpriteAnimationGroupComponent<ChickenState>
    with HasGameRef {
  static const double sourceFrameWidth = 16;
  static const double sourceFrameHeight = 16;

  // Chicken is drawn at 32x32 even though the source frames are 16x16.
  static const double renderSize = 32;

  static const double walkSpeed = 25;

  final Random _random = Random();

  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _happyAnimation;
  late SpriteAnimation _walkAnimation;

  ChickenDirection _direction = ChickenDirection.right;

  double _stateTimer = 0;

  Chicken()
      : super(
          size: Vector2.all(renderSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await _loadAnimations();

    current = ChickenState.idle;
    _stateTimer = _randomIdleDuration();
  }

  Future<void> _loadAnimations() async {
    final data = await rootBundle.load(
      'assets/tilesets/Chicken.png',
    );

    final bytes = data.buffer.asUint8List();

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    final spriteSheet = frame.image;

    // ------------------------------------------------------------
    // ROW 0 - FRAME 0
    // Normal idle
    // ------------------------------------------------------------
    _idleAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1.0,
        textureSize: Vector2(
          sourceFrameWidth,
          sourceFrameHeight,
        ),
        texturePosition: Vector2(
          0,
          0,
        ),
      ),
    );

    // ------------------------------------------------------------
    // ROW 0 - FRAME 1
    // Happy idle
    // ------------------------------------------------------------
    _happyAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 0.8,
        textureSize: Vector2(
          sourceFrameWidth,
          sourceFrameHeight,
        ),
        texturePosition: Vector2(
          sourceFrameWidth,
          0,
        ),
      ),
    );

    // ------------------------------------------------------------
    // ROW 1 - FRAMES 0,1,2,3
    // Walking right
    // ------------------------------------------------------------
    _walkAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 4,
        amountPerRow: 4,
        stepTime: 0.15,
        textureSize: Vector2(
          sourceFrameWidth,
          sourceFrameHeight,
        ),
        texturePosition: Vector2(
          0,
          sourceFrameHeight,
        ),
      ),
    );

    animations = {
      ChickenState.idle: _idleAnimation,
      ChickenState.walk: _walkAnimation,
      ChickenState.happy: _happyAnimation,
    };
  }

  @override
  @override
void update(double dt) {
  super.update(dt);

  // Lower objects on the screen render in front.
priority = 1000 + position.y.toInt();
  _stateTimer -= dt;

  if (_stateTimer <= 0) {
    _chooseNextAction();
  }

  if (current != ChickenState.walk) {
    return;
  }

  _move(dt);
}

  void _chooseNextAction() {
    final roll = _random.nextDouble();

    if (roll < 0.15) {
      _startHappy();
    } else if (roll < 0.55) {
      _startIdle();
    } else {
      _startWalking();
    }
  }

  void _startIdle() {
    current = ChickenState.idle;

    scale.x = 1;

    _stateTimer = _randomIdleDuration();
  }

  void _startHappy() {
    current = ChickenState.happy;

    scale.x = 1;

    _stateTimer = 0.8;
  }

  void _startWalking() {
    current = ChickenState.walk;

    _direction = _random.nextBool()
        ? ChickenDirection.left
        : ChickenDirection.right;

    scale.x = _direction == ChickenDirection.left ? -1 : 1;

    _stateTimer = 1.0 + _random.nextDouble() * 2.0;
  }

  void _move(double dt) {
    final direction =
        _direction == ChickenDirection.right ? 1.0 : -1.0;

    final amount = direction * walkSpeed * dt;

    _moveHorizontal(amount);
  }

  void _moveHorizontal(double amount) {
    if (amount == 0) return;

    const maxStep = 1.5;

    final steps = (amount.abs() / maxStep).ceil();
    final step = amount / steps;

    for (var i = 0; i < steps; i++) {
      final nextPosition = position.clone();

      nextPosition.x += step;

      if (_collidesAt(nextPosition)) {
        _turnAround();
        return;
      }

      position.setFrom(nextPosition);
    }
  }

  void _turnAround() {
    _direction = _direction == ChickenDirection.left
        ? ChickenDirection.right
        : ChickenDirection.left;

    scale.x = _direction == ChickenDirection.left ? -1 : 1;

    _startIdle();
  }

  bool _collidesAt(Vector2 testPosition) {
    // Small footprint around the chicken's feet.
    const hitboxWidth = 30.0;
    const hitboxHeight = 7.0;

    final chickenRect = Rect.fromLTWH(
      testPosition.x - hitboxWidth / 2,
      testPosition.y + 7 - hitboxHeight / 2,
      hitboxWidth,
      hitboxHeight,
    );

    final blocks =
        parent?.children.whereType<CollisionBlock>() ?? [];

    for (final block in blocks) {
      final blockRect = Rect.fromLTWH(
        block.position.x,
        block.position.y,
        block.size.x,
        block.size.y,
      );

      if (chickenRect.overlaps(blockRect)) {
        return true;
      }
    }

    return false;
  }

  double _randomIdleDuration() {
    return 1.0 + _random.nextDouble() * 2.5;
  }

  /// Makes the chicken play its happy animation immediately.
  void makeHappy() {
    current = ChickenState.happy;
    _stateTimer = 0.8;
  }
}