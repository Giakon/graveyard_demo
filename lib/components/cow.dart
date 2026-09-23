import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game.dart';
import 'collision_block.dart';
import 'player.dart';

enum CowState { idle, walk }
enum CowDirection { left, right }

class Cow extends SpriteAnimationGroupComponent<CowState>
    with HasGameRef {
  static const double sourceFrameWidth = 32;
  static const double sourceFrameHeight = 32;
  static const double renderSize = 48;
  static const double walkSpeed = 15;
  static const double interactDistance = 30;
  static const double milkCooldown = 30.0;

  final Random _random = Random();

  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _walkAnimation;

  CowDirection _direction = CowDirection.right;
  double _stateTimer = 0;

  bool playerNearby = false;
  bool onCooldown = false;
  double _cooldownTimer = 0;
  double _cooldownTotal = 0;

  Cow()
      : super(
          size: Vector2.all(renderSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAnimations();
    current = CowState.idle;
    _stateTimer = _randomIdleDuration();
    priority = 1000 + position.y.toInt();
  }

  Future<void> _loadAnimations() async {
    final data = await rootBundle.load('assets/tilesets/Cow.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final spriteSheet = frame.image;

    _idleAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1.0,
        textureSize: Vector2(sourceFrameWidth, sourceFrameHeight),
        texturePosition: Vector2(0, 0),
      ),
    );

    _walkAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.2,
        textureSize: Vector2(sourceFrameWidth, sourceFrameHeight),
        texturePosition: Vector2(0, sourceFrameHeight),
      ),
    );

    animations = {
      CowState.idle: _idleAnimation,
      CowState.walk: _walkAnimation,
    };
  }

  // ============================================================
  // INTERACT
  // ============================================================

  void interact() {
    if (!playerNearby || onCooldown) return;

    final game = findGame()! as BeachHouseGame;
    game.inventory.add('milk');

    onCooldown = true;
    _cooldownTimer = milkCooldown;
    _cooldownTotal = milkCooldown;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  void update(double dt) {
    super.update(dt);

    priority = 1000 + position.y.toInt();

    // cooldown
    if (onCooldown) {
      _cooldownTimer -= dt;
      if (_cooldownTimer <= 0) {
        onCooldown = false;
        _cooldownTimer = 0;
      }
    }

    // check player nearby
    final player = parent?.children.whereType<Player>().firstOrNull;
    playerNearby = player != null &&
        absoluteCenter.distanceTo(player.absoluteCenter) <=
            interactDistance;

    // state timer
    _stateTimer -= dt;
    if (_stateTimer <= 0) _chooseNextAction();

    if (current == CowState.walk) _move(dt);
  }

  // ============================================================
  // RENDER — E PROMPT
  // ============================================================

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

    canvas.drawRRect(
      promptRect,
      Paint()
        ..color = (onCooldown ? Colors.grey : Colors.black)
            .withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      promptRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // cooldown arc
    if (onCooldown) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.x / 2, -promptHeight / 2 - 2),
          width: promptWidth,
          height: promptHeight,
        ),
        -3.14 / 2,
        3.14 * 2 * (1 - _cooldownTimer / _cooldownTotal),
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
          color: onCooldown ? Colors.grey[300] : Colors.white,
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
        -promptHeight - 2 + (promptHeight - textPainter.height) / 2,
      ),
    );
  }

  // ============================================================
  // MOVEMENT
  // ============================================================

  void _chooseNextAction() {
    if (_random.nextDouble() < 0.55) {
      _startIdle();
    } else {
      _startWalking();
    }
  }

  void _startIdle() {
    current = CowState.idle;
    scale.x = 1;
    _stateTimer = _randomIdleDuration();
  }

  void _startWalking() {
    current = CowState.walk;
    _direction = _random.nextBool()
        ? CowDirection.left
        : CowDirection.right;
    scale.x = _direction == CowDirection.left ? -1 : 1;
    _stateTimer = 1.5 + _random.nextDouble() * 3.0;
  }

  void _move(double dt) {
    final direction = _direction == CowDirection.right ? 1.0 : -1.0;
    _moveHorizontal(direction * walkSpeed * dt);
  }

  void _moveHorizontal(double amount) {
    if (amount == 0) return;

    const maxStep = 2.0;
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
    _direction = _direction == CowDirection.left
        ? CowDirection.right
        : CowDirection.left;
    scale.x = _direction == CowDirection.left ? -1 : 1;
    _startIdle();
  }

  bool _collidesAt(Vector2 testPosition) {
    const hitboxWidth = 36.0;
    const hitboxHeight = 12.0;

    final cowRect = Rect.fromLTWH(
      testPosition.x - hitboxWidth / 2,
      testPosition.y + 14 - hitboxHeight / 2,
      hitboxWidth,
      hitboxHeight,
    );

    final blocks = parent?.children.whereType<CollisionBlock>() ?? [];

    for (final block in blocks) {
      final blockRect = Rect.fromLTWH(
        block.position.x,
        block.position.y,
        block.size.x,
        block.size.y,
      );

      if (cowRect.overlaps(blockRect)) return true;
    }

    return false;
  }

  double _randomIdleDuration() => 1.5 + _random.nextDouble() * 3.0;
}