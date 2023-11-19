import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame_tiled_example/background_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Background extends StatefulWidget {
  const Background({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  late final ui.Image _background;
  bool _isBackgroundLoaded = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future init() async {
    final data = await rootBundle.load('assets/images/background.webp');
    _background = await loadImage(Uint8List.view(data.buffer));
  }

  Future<ui.Image> loadImage(Uint8List img) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(img, (ui.Image img) {
      setState(() {
        _isBackgroundLoaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if(_isBackgroundLoaded) {
      return CustomPaint(
        painter: BackgroundPainter(backgroundImage: _background),
        child: Container(
          constraints: const BoxConstraints.expand(),
          child: widget.child,
        ),
      );
    } else {
      return Container(
        constraints: const BoxConstraints.expand(),
        child: null,
      );
    }
  }
}