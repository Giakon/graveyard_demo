import 'package:flame/components.dart';

import '../components/cat.dart';
import '../components/player.dart';
import '../game.dart';

mixin CatSceneMixin on World {
  Player get scenePlayer;

  void setupCat() {
    final game = findGame()! as BeachHouseGame;
    final existingCat = game.followingCat;

    if (existingCat != null) {
      // remove from previous scene if still attached
      if (existingCat.parent != null) {
        existingCat.removeFromParent();
      }
      existingCat.position = scenePlayer.position + Vector2(20, 0);
      add(existingCat);
    }
  }

  void onCatInteracted(Cat cat) {
    final game = findGame()! as BeachHouseGame;
    game.followingCat = cat;
  }
}