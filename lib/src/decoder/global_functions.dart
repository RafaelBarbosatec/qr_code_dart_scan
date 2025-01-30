import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:zxing_lib/zxing.dart';

///
/// Created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 28/06/22

Future<ui.Image> myDecodeImageFromList(Uint8List bytes) {
  Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(bytes, (image) => completer.complete(image));
  return completer.future;
}

LuminanceSource transformToLuminanceSource(List<Plane> planes, {bool forceReadPortrait = false}) {
  final e = planes.first;
  int width = e.bytesPerRow;
  int height = (e.bytes.length / width).round();
  final total = planes
      .map<double>((p) => (p.bytesPerPixel ?? 1).toDouble())
      .reduce((value, element) => value + 1 / element)
      .toInt();
  Uint8List data = Uint8List(width * height * total);
  int startIndex = 0;
  for (var p in planes) {
    List.copyRange(data, startIndex, p.bytes);
    startIndex += width * height ~/ (p.bytesPerPixel ?? 1);
  }

  final isLandscape = height < width;

  if (isLandscape && forceReadPortrait) {
    // rotaciona a imagem 90 graus
    final rotatedData = Uint8List(width * height * total);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        rotatedData[x * height + height - y - 1] = data[y * width + x];
      }
    }
    width = height;
    height = width;
    data = rotatedData;
  }

  return PlanarYUVLuminanceSource(
    data,
    width,
    height,
  );
}
