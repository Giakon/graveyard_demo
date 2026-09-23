import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'components/cat.dart';
import 'components/player.dart';
import 'inventory.dart';
import 'scenes/town_scene.dart';
import 'scenes/first_floor_scene.dart';
import 'scenes/second_floor_scene.dart';
import 'scenes/third_floor_scene.dart';
import 'package:flutter/foundation.dart';

class BeachHouseGame extends FlameGame with HasKeyboardHandlerComponents {
  late final RouterComponent router;

  bool gameStarted = false;
  Cat? followingCat;
  bool picnicRugCollected = false;
  bool redDressCollected = false;

  bool picnicRugPlaced = false;
  final seenThoughts = <String>{};
  final inventory = Inventory();

  BeachHouseGame()
    : super(
        camera: CameraComponent.withFixedResolution(width: 320, height: 200),
      );

 final ValueNotifier<bool> showEnding = ValueNotifier(false);

void startEnding() {
  if (showEnding.value) return;

  showEnding.value = true;
}

  void dismissThoughts() {
    void propagate(Component component) {
      if (component is Player) {
        component.touchDismissThought();
      }

      for (final child in component.children) {
        propagate(child);
      }
    }

    for (final child in children) {
      propagate(child);
    }
  }

  @override
  Future<void> onLoad() async {
    add(
      router = RouterComponent(
        routes: {
          'town': WorldRoute(TownScene.new, maintainState: false),
          'town_from_house': WorldRoute(
            () => TownScene(
              spawnPoint: 'Door',
              startingDirection: PlayerDirection.down,
            ),
            maintainState: false,
          ),
          'first_floor': WorldRoute(
            () => FirstFloorScene(
              spawnPoint: 'HouseEntry',
              startingDirection: PlayerDirection.up,
            ),
            maintainState: false,
          ),
          'first_floor_from_second': WorldRoute(
            () => FirstFloorScene(
              spawnPoint: 'Stairs',
              startingDirection: PlayerDirection.left,
            ),
            maintainState: false,
          ),
          'second_floor': WorldRoute(
            () => SecondFloorScene(
              spawnPoint: 'stairs_down',
              startingDirection: PlayerDirection.left,
            ),
            maintainState: false,
          ),
          'second_floor_from_third': WorldRoute(
            () => SecondFloorScene(
              spawnPoint: 'stairs_up',
              startingDirection: PlayerDirection.left,
            ),
            maintainState: false,
          ),
          'second_floor_start_game': WorldRoute(
            () => SecondFloorScene(
              spawnPoint: 'next_to_bed',
              startingDirection: PlayerDirection.right,
            ),
            maintainState: false,
          ),
          'third_floor': WorldRoute(
            () => ThirdFloorScene(
              spawnPoint: 'stairs_down',
              startingDirection: PlayerDirection.left,
            ),
            maintainState: false,
          ),
        },
        initialRoute: 'second_floor_start_game',
      ),
    );
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // walk the entire component tree to find the player
    void propagate(Component component) {
      if (component is KeyboardHandler) {
        (component as KeyboardHandler).onKeyEvent(event, keysPressed);
      }
      for (final child in component.children) {
        propagate(child);
      }
    }

    for (final child in children) {
      propagate(child);
    }

    return super.onKeyEvent(event, keysPressed);
  }
}
