// ignore_for_file: lines_longer_than_80_chars

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame_tiled_example/background.dart';
import 'package:flame_tiled_example/tile_info.dart';
import 'package:flame_tiled_example/utils.dart';
import 'package:flutter/widgets.dart' hide Animation, Image;

void main() {
  runApp(
    Background(
      child: GameWidget(game: TiledGame()),
    ),
  );
}

class TiledGame extends FlameGame with ScaleDetector, TapDetector {
  late TiledComponent mapComponent;

  static const double _minZoom = 0.5;
  static const double _maxZoom = 2.0;
  double _startZoom = _minZoom;

  @override
  Color backgroundColor() => const Color(0x00000000); // Must be transparent to show the background

  TiledGame()
      : super(
        // TODO(AS): you should hide the system panels, calculate a read screen size
        // and pass it to the camera. How can you do it - see the hexagon pazzle sources
        // camera: CameraComponent.withFixedResolution(
        //   width: 16 * 28,
        //   height: 16 * 14,
        // ),
        );

  @override
  Future<void> onLoad() async {
    camera.viewfinder
      ..zoom = _startZoom
      ..anchor = Anchor.topLeft;

    mapComponent = await TiledComponent.load(
      'map3.tmx',
      Vector2(64, 73), // Should be as same as a size of tile in the Tiled
    );
    world.add(mapComponent);
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    _startZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final currentScale = info.scale.global;

    if (currentScale.isIdentity()) {
      // One-finger gesture
      _processDrag(info);
    } else {
      // Several fingers gesture
      _processScale(info, currentScale);
    }
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    _checkScaleBorders();
    _checkDragBorders();
  }

  @override
  Future<void> onTapUp(TapUpInfo info) async {
    final tappedCel = _getTappedCell(info);

    // final tappedCel = estimateCallTime<TileInfo>(() {
    //     return _getTappedCell(info);
    //   },
    // );

    // developer.log('cell: ${tappedCel.row}; ${tappedCel.col}');

    final spriteComponent = SpriteComponent(
      size: Vector2.all(64.0),
      sprite: await Sprite.load('unit_infantry_germany.png'),
    )
      ..anchor = Anchor.center
      ..position = Vector2(tappedCel.center.dx, tappedCel.center.dy)
      ..priority = 1;
    mapComponent.add(spriteComponent);
  }

  void _processDrag(ScaleUpdateInfo info) {
    final delta = info.delta.global;
    final zoomDragFactor = 1.0 / _startZoom; // To synchronize a drag distance with current zoom value
    final currentPosition = camera.viewfinder.position;

    camera.viewfinder.position = currentPosition.translated(
      -delta.x * zoomDragFactor,
      -delta.y * zoomDragFactor,
    );
  }

  void _processScale(ScaleUpdateInfo info, Vector2 currentScale) {
    final newZoom = _startZoom * ((currentScale.y + currentScale.x) / 2.0);
    camera.viewfinder.zoom = newZoom.clamp(_minZoom, _maxZoom);
  }

  void _checkScaleBorders() {
    camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(_minZoom, _maxZoom);
  }

  void _checkDragBorders() {
    final worldRect = camera.visibleWorldRect;

    final currentPosition = camera.viewfinder.position;

    final mapSize = Offset(mapComponent.width, mapComponent.height);

    var xTranslate = 0.0;
    var yTranslate = 0.0;

    if (worldRect.topLeft.dx < 0.0) {
      xTranslate = -worldRect.topLeft.dx;
    } else if (worldRect.bottomRight.dx > mapSize.dx) {
      xTranslate = mapSize.dx - worldRect.bottomRight.dx;
    }

    if (worldRect.topLeft.dy < 0.0) {
      yTranslate = -worldRect.topLeft.dy;
    } else if (worldRect.bottomRight.dy > mapSize.dy) {
      yTranslate = mapSize.dy - worldRect.bottomRight.dy;
    }

    camera.viewfinder.position = currentPosition.translated(xTranslate, yTranslate);
  }

  TileInfo _getTappedCell(TapUpInfo info) {
    final clickOnMapPoint = camera.globalToLocal(info.eventPosition.global);

    final rows = mapComponent.tileMap.map.width;
    final cols = mapComponent.tileMap.map.height;

    final tileSize = mapComponent.tileMap.destTileSize;

    var targetRow = 0;
    var targetCol = 0;
    var minDistance = double.maxFinite;
    var targetCenter = Offset.zero;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final xCenter = col * tileSize.x + tileSize.x / 2 + (row.isEven ? 0 : tileSize.x / 2);
        final yCenter = row * tileSize.y - (row * tileSize.y / 4) + tileSize.y / 2;

        final distance = math.sqrt(math.pow(xCenter - clickOnMapPoint.x, 2) + math.pow(yCenter - clickOnMapPoint.y, 2));

        if (distance < minDistance) {
          minDistance = distance;
          targetRow = row;
          targetCol = col;
          targetCenter = Offset(xCenter, yCenter);
        }
      }
    }

    return TileInfo(center: targetCenter, row: targetRow, col: targetCol);
  }
}
