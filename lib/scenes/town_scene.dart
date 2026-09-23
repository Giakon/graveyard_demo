import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart';
import '../components/thought_trigger.dart';
import '../components/interactable.dart';
import '../components/chicken.dart';
import '../components/player.dart';
import '../components/collision_block.dart';
import '../game.dart';
import '../components/cow.dart';
import '../components/house_door.dart';
import '../components/picnic_rug.dart';
import 'cat_scene_mixin.dart';

class TownScene extends World
    with HasCollisionDetection, CatSceneMixin {
  TownScene({
    this.spawnPoint = 'PlayerStart',
    this.startingDirection = PlayerDirection.down,
  });

  final String spawnPoint;
  final PlayerDirection startingDirection;

  late final TiledComponent groundMap;
  late final TiledComponent decorationMap;
  late final TiledComponent decorationTopMap;
  late final Player player;

  @override
  Player get scenePlayer => player;

  static const double renderedTileSize = 16;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ------------------------------------------------------------
    // MAPS
    // ------------------------------------------------------------

    groundMap = await _loadMapWithLayers({'ground'});
    decorationMap =
        await _loadMapWithLayers({'decoration'});
    decorationTopMap =
        await _loadMapWithLayers({'decoration_top'});

    groundMap.priority = 0;
    decorationMap.priority = 100;
    decorationTopMap.priority = 100000;

    add(groundMap);
    add(decorationMap);

    // ------------------------------------------------------------
    // COLLISIONS
    // ------------------------------------------------------------

    await _loadTileCollisions(groundMap);
    await _loadObjectCollisions(groundMap);


    // ------------------------------------------------------------
    // PLAYER
    // ------------------------------------------------------------

    player = Player(
      startingDirection: startingDirection,
    );

    player.position = _findSpawnPoint();

    add(player);
    await _loadThoughts(groundMap);

    // ------------------------------------------------------------
    // INTERACTABLES
    // ------------------------------------------------------------

    await _loadInteractables(groundMap);

    // ------------------------------------------------------------
    // PICNIC SPOT
    // ------------------------------------------------------------

    await _loadPicnicSpot(groundMap);

    // ------------------------------------------------------------
    // HOUSE DOORS
    // ------------------------------------------------------------

    await _loadHouseDoors(groundMap);

    // ------------------------------------------------------------
    // CHICKENS
    // ------------------------------------------------------------

    final chicken1 = Chicken();
    chicken1.position = Vector2(160, 120);
    add(chicken1);

    final chicken2 = Chicken();
    chicken2.position = Vector2(170, 155);
    add(chicken2);

    final chicken3 = Chicken();
    chicken3.position = Vector2(150, 180);
    add(chicken3);

    // ------------------------------------------------------------
    // COWS
    // ------------------------------------------------------------

    final cow1 = Cow();
    cow1.position = Vector2(150, 40);
    add(cow1);

    final cow2 = Cow();
    cow2.position = Vector2(200, 15);
    add(cow2);

    // ------------------------------------------------------------
    // TOP DECORATION
    // ------------------------------------------------------------

    add(decorationTopMap);
  }
Future<void> _loadThoughts(TiledComponent sourceMap) async {
  final tiledMap = sourceMap.tileMap.map;

  for (final layer in tiledMap.layers) {
    if (layer is! ObjectGroup) continue;

    for (final object in layer.objects) {
      if (object.name != 'thought') continue;

      final textProp = object.properties
          .where((p) => p.name == 'text')
          .firstOrNull;
      final text = textProp?.value as String?;

      if (text == null || text.isEmpty) continue;

      add(
        ThoughtTrigger(
          position: Vector2(object.x, object.y),
          text: text,
          triggerRadius: 24,
        ),
      );

      print('Loaded thought at ${object.x}, ${object.y}: $text');
    }
  }
}
  // ============================================================
  // SPAWN POINT
  // ============================================================

  Vector2 _findSpawnPoint() {
    final tiledMap = groundMap.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;

      for (final object in layer.objects) {
        if (object.name == spawnPoint) {
          return Vector2(
            object.x,
            object.y,
          );
        }

        if (spawnPoint == 'Door' &&
            object.name == 'Door' &&
            object.class_ == 'house_door') {
          return Vector2(
            object.x + object.width / 2,
            object.y + object.height + 120,
          );
        }
      }
    }

    print(
      'WARNING: $spawnPoint spawn point not found, '
      'using default.',
    );

    return Vector2(280, 85);
  }

  // ============================================================
  // MAP LOADING
  // ============================================================

  Future<TiledComponent> _loadMapWithLayers(
    Set<String> visibleLayerNames,
  ) async {
    final component = await TiledComponent.load(
      'town.tmx',
      Vector2.all(renderedTileSize),
      prefix: 'assets/maps/',
             useAtlas: false,

    );

    final tiledMap = component.tileMap.map;

    for (var index = 0;
        index < tiledMap.layers.length;
        index++) {
      final layer = tiledMap.layers[index];

      final shouldBeVisible =
          visibleLayerNames.contains(layer.name);

      component.tileMap.setLayerVisibility(
        index,
        visible: shouldBeVisible,
      );
    }

    return component;
  }

  // ============================================================
  // TILESET COLLISIONS
  // ============================================================

  Future<void> _loadTileCollisions(
    TiledComponent sourceMap,
  ) async {
    final tileMap = sourceMap.tileMap;
    final tiledMap = tileMap.map;

    final scaleX =
        renderedTileSize /
            tiledMap.tileWidth.toDouble();

    final scaleY =
        renderedTileSize /
            tiledMap.tileHeight.toDouble();

    int count = 0;

    for (final layer in tiledMap.layers) {
      if (layer is! TileLayer) continue;

      for (var y = 0;
          y < tiledMap.height;
          y++) {
        for (var x = 0;
            x < tiledMap.width;
            x++) {
          final gid =
              layer.tileData?[y][x].tile;

          if (gid == null || gid == 0) {
            continue;
          }

          final tile =
              tileMap.map.tileByGid(gid);

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

            if (size.x <= 0 ||
                size.y <= 0) {
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
      'Loaded $count tileset collision blocks',
    );
  }

  // ============================================================
  // TILED OBJECT-LAYER COLLISIONS
  // ============================================================

  Future<void> _loadObjectCollisions(
    TiledComponent sourceMap,
  ) async {
    final tiledMap = sourceMap.tileMap.map;

    final scaleX =
        renderedTileSize /
            tiledMap.tileWidth.toDouble();

    final scaleY =
        renderedTileSize /
            tiledMap.tileHeight.toDouble();

    int count = 0;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;
      if (layer.name != 'collision') continue;

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
      'Loaded $count Tiled object collision blocks',
    );
  }

  // ============================================================
  // INTERACTABLES
  // ============================================================

  Future<void> _loadInteractables(
    TiledComponent sourceMap,
  ) async {
    final tiledMap = sourceMap.tileMap.map;

    const cooldowns = {
      'tree': 8.0,
      'horseradish': 10.0,
      'carrots': 10.0,
      'coop': 30.0,
      'oven': 15.0,
      'fridge': 0.0,
    };

    const itemMap = {
      'tree': 'apple',
      'horseradish': 'horseradish',
      'carrots': 'carrot',
      'coop': 'egg',
      'oven': 'cooked',
      'fridge': 'apple',
    };

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;

      for (final object in layer.objects) {
        final itemId =
            itemMap[object.name];

        if (itemId == null) {
          continue;
        }

        add(
          Interactable(
            position: Vector2(
              object.x,
              object.y,
            ),
            size: Vector2(
              object.width > 0
                  ? object.width
                  : 16,
              object.height > 0
                  ? object.height
                  : 16,
            ),
            itemId: itemId,
            player: player,
            cooldown:
                cooldowns[object.name] ?? 5.0,
          )..priority = 200000,
        );
      }
    }
  }

  // ============================================================
  // PICNIC SPOT
  // ============================================================

  Future<void> _loadPicnicSpot(
    TiledComponent sourceMap,
  ) async {
    final tiledMap = sourceMap.tileMap.map;
    final game =
        findGame()! as BeachHouseGame;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;

      for (final object in layer.objects) {
        if (object.name != 'picnic_spot') {
          continue;
        }

        final position = Vector2(
          object.x +
              object.width / 2,
          object.y +
              object.height / 2,
        );

        // --------------------------------------------------------
        // RUG HAS ALREADY BEEN PLACED
        // --------------------------------------------------------

        if (game.picnicRugPlaced) {
          final rug = PlacedPicnicRug(
            position: position,
          );

          rug.priority = 1000;

          add(rug);

          print(
            'Placed picnic rug at $position',
          );
        }

        // --------------------------------------------------------
        // RUG HAS NOT BEEN PLACED
        // --------------------------------------------------------

        else {
          add(
            Interactable(
              position: Vector2(
                object.x,
                object.y,
              ),
              size: Vector2(
                object.width > 0
                    ? object.width
                    : 16,
                object.height > 0
                    ? object.height
                    : 16,
              ),
              itemId: 'picnic_spot',
              player: player,
              cooldown: 0,
            )..priority = 200000,
          );

          print(
            'Loaded picnic spot at '
            '${object.x}, ${object.y}',
          );
        }
      }
    }
  }

  // ============================================================
  // HOUSE DOORS
  // ============================================================

  Future<void> _loadHouseDoors(
    TiledComponent sourceMap,
  ) async {
    final tiledMap = sourceMap.tileMap.map;

    for (final layer in tiledMap.layers) {
      if (layer is! ObjectGroup) continue;

      for (final object in layer.objects) {
        if (object.name != 'Door') {
          continue;
        }

        if (object.class_ != 'house_door') {
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
        );

        add(door);
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
    //game.camera.viewfinder.zoom = 1.0;

    game.camera.follow(player);

    game.camera.setBounds(
      Rectangle.fromLTRB(
        160,
        100,
        480,
        300,
      ),
    );

    setupCat();
  }
}