import 'package:flame/components.dart';

import '../game.dart';
import 'player.dart';
import 'thought_bubble.dart';

class ThoughtTrigger extends PositionComponent {
  ThoughtTrigger({
    required Vector2 position,
    required this.text,
    this.triggerRadius = 80.0,
  }) : super(
          position: position,
          size: Vector2.all(4),
        );

  final String text;
  final double triggerRadius;

  bool _triggered = false;

  @override
  void update(double dt) {
    super.update(dt);

    if (_triggered) return;

    final game = findGame() as BeachHouseGame?;
    if (game == null) return;

    // Don't trigger thoughts before the game has started.
    if (!game.gameStarted) return;

    if (game.seenThoughts.contains(text)) {
      _triggered = true;
      return;
    }

    final player = parent?.children
        .whereType<Player>()
        .firstOrNull;

    if (player == null) return;

    // Don't trigger if player already has a bubble showing.
    if (player.children.whereType<ThoughtBubble>().isNotEmpty) {
      return;
    }

    final distance = absoluteCenter.distanceTo(
      player.absoluteCenter,
    );

    if (distance > triggerRadius) return;

    _triggered = true;
    game.seenThoughts.add(text);

    final bubble = ThoughtBubble(fullText: text)
      ..position = Vector2(15, -8)
      ..priority = 999999;

    player.add(bubble);
  }
}