import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart';
import '../components/picnic_rug.dart';
import '../components/interactable.dart';
import '../components/player.dart';
import '../components/collision_block.dart';
import '../components/house_door.dart';
import '../game.dart';
import '../components/cat.dart';
import '../components/thought_trigger.dart';
import 'cat_scene_mixin.dart';
import '../components/dress_pickup.dart';
import 'dart:ui';


class SecondFloorScene extends World
    with HasCollisionDetection, CatSceneMixin {
  SecondFloorScene({
    this.spawnPoint = 'StairsDown',
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
      'second_floor.tmx',
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

    await _loadThoughts(map); // or just map for indoor scenes

   
    // ------------------------------------------------------------
    // CAT
    // ------------------------------------------------------------

    final game = findGame()! as BeachHouseGame;

    // Spawn the cat here for the first time if not yet adopted.
    if (game.followingCat == null) {
      final cat = Cat(
        position: Vector2(128, 140),
      );

      add(cat);
    }


if (!game.picnicRugCollected) {
  add(
    PicnicRug(
      position: Vector2(190, 185),
      player: player,
    ),
  );
}
if (!game.redDressCollected) {
  add(
    DressPickup(
      position: Vector2(152, 120),
    ),
  );
}
 
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
Future<void> _loadThoughts(TiledComponent sourceMap) async {
  final tiledMap = sourceMap.tileMap.map;

  print('Loading thoughts, layers: ${tiledMap.layers.map((l) => l.name).toList()}');

  for (final layer in tiledMap.layers) {
    if (layer is! ObjectGroup) continue;

    print('Checking layer: ${layer.name}');

    for (final object in layer.objects) {
      print('  Object: ${object.name}');

      if (object.name != 'thought') continue;

      final text = object.properties.getValue<String>('text');
      print('  Found thought! text=$text');

      if (text == null || text.isEmpty) continue;

      add(
        ThoughtTrigger(
          position: Vector2(object.x, object.y),
          text: text,
          triggerRadius: 24,
        ),
      );

      print('  ThoughtTrigger added at ${object.x}, ${object.y}');
    }
  }
}
  Future<void> _loadTileCollisions() async {
    final tileMap = map.tileMap;
    final tiledMap = tileMap.map;

    final sourceTileWidth =
        tiledMap.tileWidth.toDouble();

    final sourceTileHeight =
        tiledMap.tileHeight.toDouble();

    final scaleX =
        renderedTileSize / sourceTileWidth;

    final scaleY =
        renderedTileSize / sourceTileHeight;

    int count = 0;

    for (final layer in tiledMap.layers) {
      if (layer is! TileLayer) {
        continue;
      }

      for (var y = 0; y < tiledMap.height; y++) {
        for (var x = 0; x < tiledMap.width; x++) {
          final gid = layer.tileData?[y][x].tile;

          if (gid == null || gid == 0) {
            continue;
          }

          final tile = tileMap.map.tileByGid(gid);

          if (tile == null ||
              tile.objectGroup == null) {
            continue;
          }

          final objectGroup =
              tile.objectGroup as ObjectGroup;

          for (final obj in objectGroup.objects) {
            final position = Vector2(
              x * renderedTileSize +
                  obj.x * scaleX,
              y * renderedTileSize +
                  obj.y * scaleY,
            );

            final size = Vector2(
              obj.width * scaleX,
              obj.height * scaleY,
            );

            if (size.x <= 0 || size.y <= 0) {
              continue;
            }

            add(
              CollisionBlock(
                position: position,
                size: size,
              ),
            );

            count++;
          }
        }
      }
    }

    print(
      'Loaded $count tileset collision blocks '
      'from second_floor.tmx',
    );
  }

  // ============================================================
  // TILED INTERACTABLES
  // ============================================================

  Future<void> _loadInteractables(
    TiledComponent sourceMap,
  ) async {
    final tiledMap = sourceMap.tileMap.map;

    // Cooldown per object type.
    const cooldowns = {
      'tree': 8.0,
      'horseradish': 10.0,
      'carrot': 10.0,
      'coop': 30.0,
      'oven': 15.0,
      'fridge': 0.0,
        'red_dress': 0.0, // one time pickup


      // Picnic rug is collected once.
      'picnic_rug': 0.0,
    };

    // What item each object gives.
    const itemMap = {
      'tree': 'apple',
      'horseradish': 'horseradish',
      'carrot': 'carrot',
      'coop': 'egg',
      'oven': 'cooked',
      'fridge': 'apple',
        'red_dress': 'red_dress',

      // Tiled object "picnic_rug" gives the picnic rug.
      'picnic_rug': 'picnic_rug',
    };

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) {
        continue;
      }

      for (final object in layer.objects) {
        final itemId = itemMap[object.name];

        if (itemId == null) {
          continue;
        }

        final width =
            object.width > 0
                ? object.width
                : 16.0;

        final height =
            object.height > 0
                ? object.height
                : 16.0;

        add(
          Interactable(
            position: Vector2(
              object.x,
              object.y,
            ),
            size: Vector2(
              width,
              height,
            ),
            itemId: itemId,
            player: player,
            cooldown: cooldowns[object.name] ?? 5.0,
          )..priority = 200000,
        );

        print(
          'Loaded interactable: ${object.name} '
          'at (${object.x}, ${object.y})',
        );
      }
    }
  }

  // ============================================================
  // TILED OBJECT-LAYER COLLISIONS
  // ============================================================

  Future<void> _loadObjectCollisions() async {
    final tiledMap = map.tileMap.map;

    final sourceTileWidth =
        tiledMap.tileWidth.toDouble();

    final sourceTileHeight =
        tiledMap.tileHeight.toDouble();

    final scaleX =
        renderedTileSize / sourceTileWidth;

    final scaleY =
        renderedTileSize / sourceTileHeight;

    int count = 0;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) {
        continue;
      }

      if (layer.name != 'collision') {
        continue;
      }

      for (final object in layer.objects) {
        if (object.width <= 0 ||
            object.height <= 0) {
          continue;
        }

        final position = Vector2(
          object.x * scaleX,
          object.y * scaleY,
        );

        final size = Vector2(
          object.width * scaleX,
          object.height * scaleY,
        );

        add(
          CollisionBlock(
            position: position,
            size: size,
          ),
        );

        count++;
      }
    }

    print(
      'Loaded $count Tiled object collision blocks '
      'from second_floor.tmx',
    );
  }

  // ============================================================
  // SPAWN POINT
  // ============================================================

  Vector2 _findSpawnPoint() {
    final tiledMap = map.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) {
        continue;
      }

      for (final object in layer.objects) {
        if (object.name == spawnPoint) {
          return Vector2(
            object.x,
            object.y,
          );
        }
      }
    }

    print(
      'WARNING: $spawnPoint spawn point not found.',
    );

    return Vector2(80, 100);
  }

  // ============================================================
  // EXIT TO FIRST FLOOR
  // ============================================================

  Future<void> _loadExitDoor() async {
    final tiledMap = map.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) {
        continue;
      }

      for (final object in layer.objects) {
        if (object.name != 'stairs_down') {
          continue;
        }

        final door = HouseDoor(
          position: Vector2(
            object.x,
            object.y,
          ),
          size: Vector2(
            object.width,
            object.height,
          ),
          player: player,
          destinationRoute:
              'first_floor_from_second',
        );

        add(door);
      }
    }
  }

  // ============================================================
  // STAIRS UP TO THIRD FLOOR
  // ============================================================

  Future<void> _loadStairsUp() async {
    final tiledMap = map.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) {
        continue;
      }

      for (final object in layer.objects) {
        if (object.name != 'stairs_up') {
          continue;
        }

        final stairs = HouseDoor(
          position: Vector2(
            object.x,
            object.y,
          ),
          size: Vector2(
            object.width,
            object.height,
          ),
          player: player,
          destinationRoute: 'third_floor',
        );

        add(stairs);
      }
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  @override
  void onMount() {
    super.onMount();

    final game =
        findGame()! as BeachHouseGame;

    game.camera.viewfinder.anchor =
        Anchor.center;
   game.camera.viewfinder.zoom = 1.25;

    game.camera.follow(player);

    setupCat();
  }
}