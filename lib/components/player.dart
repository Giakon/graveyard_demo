import 'dart:ui' as ui;

import 'dress_pickup.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';

import 'thought_bubble.dart';
import 'cat.dart';
import 'interactable.dart';
import 'collision_block.dart';
import 'house_door.dart';
import '../game.dart';
import 'cow.dart';
import 'picnic_rug.dart';
import '../data/task.dart';
import '../services/task_service.dart';

enum PlayerDirection { down, up, left, right }

enum PlayerState { idle, walk }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameRef, KeyboardHandler {
  static const double speed = 100;
  static const double frameWidth = 32;
  static const double frameHeight = 32;

  Player({PlayerDirection startingDirection = PlayerDirection.down})
    : _direction = startingDirection,
      super(size: Vector2(32, 32), anchor: Anchor.center);

  final _keys = <LogicalKeyboardKey>{};

  PlayerDirection _direction;
  PlayerState _state = PlayerState.idle;

  late SpriteAnimation _walkDown;
  late SpriteAnimation _walkUp;
  late SpriteAnimation _walkRight;

  late SpriteAnimation _idleDown;
  late SpriteAnimation _idleUp;
  late SpriteAnimation _idleRight;

  // Prevent the final completion message from appearing more than once.
  bool _completionThoughtShown = false;
  ThoughtBubble? _completionThoughtBubble;
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await _loadAnimations();

    _setInitialAnimation();

    current = PlayerState.idle;
  }

  void _setInitialAnimation() {
    switch (_direction) {
      case PlayerDirection.down:
        scale.x = 1;

        animations = {PlayerState.idle: _idleDown, PlayerState.walk: _walkDown};
        break;

      case PlayerDirection.up:
        scale.x = 1;

        animations = {PlayerState.idle: _idleUp, PlayerState.walk: _walkUp};
        break;

      case PlayerDirection.left:
        scale.x = -1;

        animations = {
          PlayerState.idle: _idleRight,
          PlayerState.walk: _walkRight,
        };
        break;

      case PlayerDirection.right:
        scale.x = 1;

        animations = {
          PlayerState.idle: _idleRight,
          PlayerState.walk: _walkRight,
        };
        break;
    }
  }

  Future<void> _loadAnimations() async {
    final data = await rootBundle.load('assets/tilesets/Player.png');

    final bytes = data.buffer.asUint8List();

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final spriteSheet = frame.image;

    SpriteAnimation anim(int row, int frameCount, {double stepTime = 0.15}) {
      return SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: frameCount,
          amountPerRow: frameCount,
          stepTime: stepTime,
          textureSize: Vector2(frameWidth, frameHeight),
          texturePosition: Vector2(0, row * frameHeight),
        ),
      );
    }

    // Walking animations
    _walkDown = anim(3, 6);
    _walkRight = anim(4, 6);
    _walkUp = anim(5, 6);

    // Idle animations
    _idleDown = anim(0, 1, stepTime: 1.0);

    _idleRight = anim(1, 1, stepTime: 1.0);

    _idleUp = anim(2, 1, stepTime: 1.0);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    print('KEY EVENT: ${event.logicalKey.debugName}');

    _keys
      ..clear()
      ..addAll(keysPressed);

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      _interactWithDoor();
    }

    void _dismissThought() {
      final bubbles = children.whereType<ThoughtBubble>();

      for (final bubble in bubbles) {
        bubble.dismiss();
      }
    }

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyF) {
      _dismissThought();
    }

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyX) {
      _interactWithCat();
    }

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyZ) {
      // Try normal environment interaction first.
      //
      // If there wasn't one, try the cow and dress.
      if (!_interactWithEnvironment()) {
        _interactWithCow();
        _interactWithDress();
      }
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // DRESS
  // ---------------------------------------------------------------------------

  void _interactWithDress() {
    final dresses = parent?.children.whereType<DressPickup>() ?? [];

    for (final dress in dresses) {
      if (!dress.playerNearby) {
        continue;
      }

      dress.interact();

      final game = findGame()! as BeachHouseGame;

      game.overlays.add('itemPickup');

      Future.delayed(
        const Duration(seconds: 1),
        () => game.overlays.remove('itemPickup'),
      );

      TaskService.instance.complete(TaskId.pickupRedDress);

      game.redDressCollected = true;

      return;
    }
  }

  // ---------------------------------------------------------------------------
  // COW
  // ---------------------------------------------------------------------------

  void _interactWithCow() {
    final cows = parent?.children.whereType<Cow>() ?? [];

    for (final cow in cows) {
      if (!cow.playerNearby || cow.onCooldown) {
        continue;
      }

      // Cow.interact() already adds the milk.
      cow.interact();

      final game = findGame()! as BeachHouseGame;

      TaskService.instance.complete(TaskId.collectMilk);

      game.overlays.add('itemPickup');

      Future.delayed(
        const Duration(seconds: 1),
        () => game.overlays.remove('itemPickup'),
      );

      return;
    }
  }

  // ---------------------------------------------------------------------------
  // ENVIRONMENT
  // ---------------------------------------------------------------------------

  bool _interactWithEnvironment() {
    print('checking interactables');

    final interactables = parent?.children.whereType<Interactable>() ?? [];

    print('found ${interactables.length} interactables');

    for (final interactable in interactables) {
      print(
        'nearby: ${interactable.playerNearby}, '
        'cooldown: ${interactable.onCooldown}',
      );

      if (!interactable.playerNearby) {
        continue;
      }

      if (interactable.onCooldown) {
        continue;
      }

      final game = findGame()! as BeachHouseGame;

      // ----------------------------------------------------------
      // PICNIC SPOT
      // ----------------------------------------------------------

      if (interactable.itemId == 'picnic_spot') {
        if (game.picnicRugPlaced) {
          return true;
        }

        if (game.inventory.count('picnic_rug') <= 0) {
          return true;
        }

        // Remove the rug from inventory.
        final removed = game.inventory.remove('picnic_rug');

        if (!removed) {
          return true;
        }

        interactable.interact();

        // Remember that the rug has been placed.
        game.picnicRugPlaced = true;

        // Spawn the decorative placed rug.
        parent?.add(
          PlacedPicnicRug(
            position: Vector2(
              interactable.position.x + interactable.size.x / 2,
              interactable.position.y + interactable.size.y / 2,
            ),
          )..priority = 1000,
        );

        // Remove the interaction prompt/spot.
        interactable.removeFromParent();

        TaskService.instance.complete(TaskId.putRagAtBeach);

        return true;
      }

      // ----------------------------------------------------------
      // OVEN - COOKED
      // ----------------------------------------------------------

      if (interactable.itemId == 'cooked') {
        const ingredients = ['carrot', 'horseradish'];

        if (!_canCookBreakfast(game)) {
          _showMissingIngredients(game, ingredients);

          return true;
        }

        interactable.interact();

        _cookBreakfast(game);

        game.overlays.add('itemPickup');

        Future.delayed(
          const Duration(seconds: 1),
          () => game.overlays.remove('itemPickup'),
        );

        return true;
      }

      // ----------------------------------------------------------
      // OVEN - CAKE
      // ----------------------------------------------------------

      if (interactable.itemId == 'cake') {
        const ingredients = ['egg', 'milk', 'apple'];

        if (!_canMakeCake(game)) {
          _showMissingIngredients(game, ingredients);

          return true;
        }

        interactable.interact();

        _makeCake(game);

        game.overlays.add('itemPickup');

        Future.delayed(
          const Duration(seconds: 1),
          () => game.overlays.remove('itemPickup'),
        );

        return true;
      }

      // ----------------------------------------------------------
      // NORMAL ENVIRONMENT ITEMS
      // ----------------------------------------------------------

      interactable.interact();

      game.inventory.add(interactable.itemId);

      switch (interactable.itemId) {
        case 'apple':
          TaskService.instance.complete(TaskId.collectApple);
          break;

        case 'carrot':
          TaskService.instance.complete(TaskId.collectCarrot);
          break;

        case 'horseradish':
          TaskService.instance.complete(TaskId.collectHorseradish);
          break;

        case 'egg':
          TaskService.instance.complete(TaskId.collectEgg);
          break;

        case 'waffles':
          TaskService.instance.complete(TaskId.getWafflesFromFridge);
          break;

        case 'red_dress':
          game.inventory.add('present');

          // Remove the interactable so it can't
          // be picked up again.
          interactable.removeFromParent();
          break;

        case 'picnic_rug':
          game.picnicRugCollected = true;

          TaskService.instance.complete(TaskId.getPicnicRug);

          interactable.removeFromParent();
          break;
      }

      game.overlays.add('itemPickup');

      Future.delayed(
        const Duration(seconds: 1),
        () => game.overlays.remove('itemPickup'),
      );

      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // MISSING INGREDIENT MESSAGE
  // ---------------------------------------------------------------------------

  void _showMissingIngredients(BeachHouseGame game, List<String> ingredients) {
    final missing = ingredients
        .where((ingredient) => !game.inventory.has(ingredient))
        .toList();

    if (missing.isEmpty) {
      return;
    }

    // Don't create another thought bubble if one is
    // already showing.
    if (children.whereType<ThoughtBubble>().any((b) => !b.isDone)) {
      return;
    }

    String ingredientText;

    if (missing.length == 1) {
      ingredientText = missing.first;
    } else if (missing.length == 2) {
      ingredientText = '${missing[0]} and ${missing[1]}';
    } else {
      ingredientText =
          '${missing.sublist(0, missing.length - 1).join(', ')}, '
          'and ${missing.last}';
    }

    final bubble = ThoughtBubble(fullText: 'I still need: $ingredientText.')
      ..position = Vector2(15, -8)
      ..priority = 999999;

    add(bubble);
  }

  // ---------------------------------------------------------------------------
  // BREAKFAST
  // ---------------------------------------------------------------------------

  bool _canMakeCake(BeachHouseGame game) {
    const ingredients = ['egg', 'milk', 'apple'];

    for (final ingredient in ingredients) {
      if (!game.inventory.has(ingredient)) {
        return false;
      }
    }

    return true;
  }

  void _makeCake(BeachHouseGame game) {
    const ingredients = ['egg', 'milk', 'apple'];

    // Consume all ingredients.
    for (final ingredient in ingredients) {
      game.inventory.remove(ingredient);
    }

    // Give the finished cake.
    game.inventory.add('cake');

    // Complete the task.
    TaskService.instance.complete(TaskId.makeCake);
  }

  bool _canCookBreakfast(BeachHouseGame game) {
    const ingredients = ['carrot', 'horseradish'];

    for (final ingredient in ingredients) {
      if (!game.inventory.has(ingredient)) {
        return false;
      }
    }

    return true;
  }

  void _cookBreakfast(BeachHouseGame game) {
    const ingredients = ['carrot', 'horseradish'];

    // Consume all ingredients.
    for (final ingredient in ingredients) {
      game.inventory.remove(ingredient);
    }

    // Give the finished breakfast.
    game.inventory.add('cooked');

    // Complete the task.
    TaskService.instance.complete(TaskId.cookBreakfast);
  }

  // ---------------------------------------------------------------------------
  // CAT
  // ---------------------------------------------------------------------------

  void _interactWithCat() {
    final cats = parent?.children.whereType<Cat>() ?? [];

    for (final cat in cats) {
      if (!cat.playerNearby) {
        continue;
      }

      final wasFollowing = cat.isFollowing;

      cat.interact();

      final game = findGame()! as BeachHouseGame;

      game.followingCat = cat.isFollowing ? cat : null;

      if (!wasFollowing && cat.isFollowing) {
        TaskService.instance.complete(TaskId.bozoFollowYou);
      }

      return;
    }
  }

  // ---------------------------------------------------------------------------
  // DOOR
  // ---------------------------------------------------------------------------

  void _interactWithDoor() {
    final doors = parent?.children.whereType<HouseDoor>() ?? [];

    for (final door in doors) {
      if (!door.playerNearby) {
        continue;
      }

      door.interact();
      return;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    final finishedBubbles = children
    .whereType<ThoughtBubble>()
    .where((b) => b.isDone)
    .toList();

for (final bubble in finishedBubbles) {
  final wasCompletionBubble =
      identical(bubble, _completionThoughtBubble);

  bubble.removeFromParent();

  if (wasCompletionBubble) {
    _completionThoughtBubble = null;

    final game = findGame() as BeachHouseGame?;

    if (game != null) {
      game.startEnding();
    }
  }
}

    final game = findGame()! as BeachHouseGame;

    // Don't allow the player to move before
    // the start screen has been dismissed.
    if (!game.gameStarted) {
      return;
    }

    // -------------------------------------------------------------------------
    // ALL TASKS COMPLETED
    // -------------------------------------------------------------------------

    if (TaskService.instance.allCompleted && !_completionThoughtShown) {
      final hasThoughtBubble = children.whereType<ThoughtBubble>().any(
        (b) => !b.isDone,
      );

      if (!hasThoughtBubble) {
        _completionThoughtShown = true;

        final bubble =
            ThoughtBubble(
                fullText:
                    "Everything is set. Let's wake up my love "
                    "and make sure she has the best day ever.",
              )
              ..position = Vector2(15, -8)
              ..priority = 999999;

        _completionThoughtBubble = bubble;

        add(bubble);
      }
    }
    priority = 1000 + position.y.toInt();

    final dx = _horizontal();
    final dy = _vertical();

    // print('MOVEMENT dx=$dx dy=$dy');

    final moving = dx != 0 || dy != 0;

    // ------------------------------------------------------------
    // Direction
    // ------------------------------------------------------------

    if (dy > 0) {
      _direction = PlayerDirection.down;
      scale.x = 1;
    } else if (dy < 0) {
      _direction = PlayerDirection.up;
      scale.x = 1;
    } else if (dx < 0) {
      _direction = PlayerDirection.left;
      scale.x = -1;
    } else if (dx > 0) {
      _direction = PlayerDirection.right;
      scale.x = 1;
    }

    // ------------------------------------------------------------
    // Animation
    //
    // Only change the animation when it actually changes.
    // Do NOT recreate the animations map every frame.
    // ------------------------------------------------------------

    final newState = moving ? PlayerState.walk : PlayerState.idle;

    final SpriteAnimation newAnimation;

    if (newState == PlayerState.walk) {
      newAnimation = switch (_direction) {
        PlayerDirection.down => _walkDown,
        PlayerDirection.up => _walkUp,
        PlayerDirection.left => _walkRight,
        PlayerDirection.right => _walkRight,
      };
    } else {
      newAnimation = switch (_direction) {
        PlayerDirection.down => _idleDown,
        PlayerDirection.up => _idleUp,
        PlayerDirection.left => _idleRight,
        PlayerDirection.right => _idleRight,
      };
    }

    final currentAnimation = animations![newState];

    // Only replace the animation if we
    // actually changed direction/state.
    if (!identical(currentAnimation, newAnimation)) {
      animations = {
        PlayerState.idle: newState == PlayerState.idle
            ? newAnimation
            : _idleDown,
        PlayerState.walk: newState == PlayerState.walk
            ? newAnimation
            : _walkDown,
      };
    }

    if (current != newState) {
      current = newState;
    }

    // ------------------------------------------------------------
    // Movement
    // ------------------------------------------------------------

    if (!moving) {
      return;
    }

    final velocity = Vector2(dx, dy);

    if (velocity.length2 > 0) {
      velocity.normalize();
    }

    final movement = velocity * speed * dt;

    _moveAxis(movement.x, true);

    _moveAxis(movement.y, false);
  }

  // ---------------------------------------------------------------------------
  // MOVEMENT / COLLISION
  // ---------------------------------------------------------------------------

  void _moveAxis(double amount, bool horizontal) {
    if (amount == 0) {
      return;
    }

    const maxStep = 2.0;

    final steps = (amount.abs() / maxStep).ceil();

    final step = amount / steps;

    for (var i = 0; i < steps; i++) {
      final nextPosition = position.clone();

      if (horizontal) {
        nextPosition.x += step;
      } else {
        nextPosition.y += step;
      }

      if (_collidesAt(nextPosition)) {
        break;
      }

      position.setFrom(nextPosition);
    }
  }

  bool _collidesAt(Vector2 testPosition) {
    // Smaller collision box around
    // the player's feet.
    //
    // The sprite is 32x32, but only
    // the lower part of the character
    // should collide with walls/fences.

    const hitboxWidth = 12.0;
    const hitboxHeight = 8.0;

    final playerRect = Rect.fromLTWH(
      testPosition.x - hitboxWidth / 2,
      testPosition.y + 6 - hitboxHeight / 2,
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

      if (playerRect.overlaps(blockRect)) {
        return true;
      }
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // INPUT
  // ---------------------------------------------------------------------------

  double _horizontal() {
    // Block movement if thought bubble
    // is showing.
    if (children.whereType<ThoughtBubble>().any((b) => !b.isDone)) {
      return 0;
    }

    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) {
      return -1;
    }

    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) {
      return 1;
    }

    return 0;
  }

  double _vertical() {
    if (children.whereType<ThoughtBubble>().any((b) => !b.isDone)) {
      return 0;
    }

    if (_keys.contains(LogicalKeyboardKey.arrowUp) ||
        _keys.contains(LogicalKeyboardKey.keyW)) {
      return -1;
    }

    if (_keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.keyS)) {
      return 1;
    }

    return 0;
  }
}
