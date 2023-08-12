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

LuminanceSource transformToLuminanceSource(List<Plane> planes) {
  final e = planes.first;
  final width = e.bytesPerRow;
  final height = (e.bytes.length / width).round();
  final total = planes
      .map<double>((p) => (p.bytesPerPixel??1).toDouble())
      .reduce((value, element) => value + 1 / element)
      .toInt();
  final data = Uint8List(width * height * total);
  int startIndex = 0;
  for (var p in planes) {
    List.copyRange(data, startIndex, p.bytes);
    startIndex += width * height ~/ (p.bytesPerPixel??1);
  }

  return PlanarYUVLuminanceSource(
    data,
    width,
    height,
  );
}
