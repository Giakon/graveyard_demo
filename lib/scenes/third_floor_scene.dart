import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart';
import '../components/interactable.dart';

import '../components/player.dart';
import '../components/collision_block.dart';
import '../components/house_door.dart';
import '../game.dart';
import 'cat_scene_mixin.dart';

class ThirdFloorScene extends World
    with HasCollisionDetection, CatSceneMixin {
  ThirdFloorScene({
    this.spawnPoint = 'stairs_down',
    this.startingDirection = PlayerDirection.left,
  });

  final String spawnPoint;
  final PlayerDirection startingDirection;
  late final TiledComponent map;
  late final Player player;

  @override
  Player get scenePlayer => player;

  static const double renderedTileSize = 16;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ------------------------------------------------------------
    // MAP
    // ------------------------------------------------------------

    map = await TiledComponent.load(
      'third_floor.tmx',
      Vector2.all(renderedTileSize),
      prefix: 'assets/maps/',
             useAtlas: false,

    );

    add(map);

    // ------------------------------------------------------------
    // COLLISIONS
    // ------------------------------------------------------------

    await _loadTileCollisions();
    await _loadObjectCollisions();
    

    // ------------------------------------------------------------
    // PLAYER
    // ------------------------------------------------------------

    player = Player(
      startingDirection: startingDirection,
    );

    player.position = _findSpawnPoint();

    add(player);

    // ------------------------------------------------------------
    // CAT
    // ------------------------------------------------------------


    // ------------------------------------------------------------
    // INTERACTION POINTS
    // ------------------------------------------------------------

    await _loadInteractables(map);
    await _loadExitDoor();
    await _loadStairsUp();
  }

  // ============================================================
  // TILESET COLLISIONS
  // ============================================================
Future<void> _loadInteractables(TiledComponent sourceMap) async {
  final tiledMap = sourceMap.tileMap.map;

  // cooldown per object type
  const cooldowns = {
    'tree':        8.0,
    'horseradish': 10.0,
    'carrot':      10.0,
    'coop':        30.0,
    'oven':        15.0,
    'fridge':      0.0, // no cooldown
      'oven_cake':   15.0,

  };

  // what item each object gives
  const itemMap = {
    'tree':        'apple',
    'horseradish': 'horseradish',
    'carrot':      'carrot',
    'coop':        'egg',
    'oven':        'cooked',
     'oven_cake':   'cake',     // new oven object in Tiled
    'fridge':      'waffles', // placeholder
  };

  for (final layer in tiledMap.layers) {
    if (layer is! ObjectGroup) continue;

    for (final object in layer.objects) {
      final itemId = itemMap[object.name];
      if (itemId == null) continue;

      add(
        Interactable(
          position: Vector2(object.x, object.y),
          size: Vector2(
            object.width > 0 ? object.width : 16,
            object.height > 0 ? object.height : 16,
          ),
          itemId: itemId,
          player: player,
          cooldown: cooldowns[object.name] ?? 5.0,
         )..priority = 200000, // same as HouseDoor
      );
    }
  }
}
  Future<void> _loadTileCollisions() async {
    final tileMap = map.tileMap;
    final tiledMap = tileMap.map;

    final scaleX = renderedTileSize / tiledMap.tileWidth.toDouble();
    final scaleY = renderedTileSize / tiledMap.tileHeight.toDouble();

    int count = 0;

    for (final layer in tiledMap.layers) {
      if (layer is! TileLayer) continue;

      for (var y = 0; y < tiledMap.height; y++) {
        for (var x = 0; x < tiledMap.width; x++) {
          final gid = layer.tileData?[y][x].tile;
          if (gid == null || gid == 0) continue;

          final tile = tileMap.map.tileByGid(gid);
          if (tile == null || tile.objectGroup == null) continue;

          final objectGroup = tile.objectGroup as ObjectGroup;

          for (final obj in objectGroup.objects) {
            final position = Vector2(
              x * renderedTileSize + obj.x * scaleX,
              y * renderedTileSize + obj.y * scaleY,
            );

            final size = Vector2(
              obj.width * scaleX,
              obj.height * scaleY,
            );

            if (size.x <= 0 || size.y <= 0) continue;

            add(CollisionBlock(position: position, size: size));
            count++;
          }
        }
      }
    }

    print('Loaded $count tileset collision blocks from third_floor.tmx');
  }

  // ============================================================
  // TILED OBJECT-LAYER COLLISIONS
  // ============================================================

  Future<void> _loadObjectCollisions() async {
    final tiledMap = map.tileMap.map;

    final scaleX = renderedTileSize / tiledMap.tileWidth.toDouble();
    final scaleY = renderedTileSize / tiledMap.tileHeight.toDouble();

    int count = 0;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;
      if (layer.name != 'collision') continue;

      for (final object in layer.objects) {
        if (object.width <= 0 || object.height <= 0) continue;

        final position = Vector2(object.x * scaleX, object.y * scaleY);
        final size = Vector2(object.width * scaleX, object.height * scaleY);

        add(CollisionBlock(position: position, size: size));
        count++;
      }
    }

    print('Loaded $count object collision blocks from third_floor.tmx');
  }

  // ============================================================
  // SPAWN POINT
  // ============================================================

  Vector2 _findSpawnPoint() {
    final tiledMap = map.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;

      for (final object in layer.objects) {
        if (object.name == spawnPoint) {
          return Vector2(object.x, object.y);
        }
      }
    }

    print('WARNING: $spawnPoint spawn point not found.');
    return Vector2(80, 100);
  }

  // ============================================================
  // EXIT TO SECOND FLOOR
  // ============================================================

  Future<void> _loadExitDoor() async {
    final tiledMap = map.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;

      for (final object in layer.objects) {
        if (object.name != 'stairs_down') continue;

        add(
          HouseDoor(
            position: Vector2(object.x, object.y),
            size: Vector2(object.width, object.height),
            player: player,
            destinationRoute: 'second_floor_from_third',
          ),
        );
      }
    }
  }

  // ============================================================
  // STAIRS UP
  // ============================================================

  Future<void> _loadStairsUp() async {
    final tiledMap = map.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;

      for (final object in layer.objects) {
        if (object.name != 'StairsUp') continue;

        add(
          HouseDoor(
            position: Vector2(object.x, object.y),
            size: Vector2(object.width, object.height),
            player: player,
            destinationRoute: 'third_floor',
          ),
        );
      }
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  @override
  void onMount() {
    super.onMount();

    final game = findGame()! as BeachHouseGame;
    game.camera.viewfinder.anchor = Anchor.center;
    game.camera.follow(player);
    setupCat();
  }
}