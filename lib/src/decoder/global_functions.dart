import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:qr_code_dart_scan/src/decoder/qr_code_dart_scan_multi_reader.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import 'decode_event.dart';

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

Result? decode(Map<dynamic, dynamic> msg) {
  try {
    DecodeCameraImageEvent event = DecodeCameraImageEvent.fromMap(msg);

    LuminanceSource source = transformToLuminanceSource(
      event.cameraImage.planes,
    );

    var bitmap = BinaryBitmap(
      HybridBinarizer(event.invert ? source.invert() : source),
    );

    final reader = QRCodeDartScanMultiReader(event.formats);
    // final reader = GenericMultipleBarcodeReader(MultiFormatReader());
    try {
      return reader.decode(bitmap);
    } catch (_) {
      return null;
    }
  } catch (e) {
    // ignore: avoid_print
    print('ERROR:$e');
  }
  return null;
}

Future<Result?> decodeImage(Map<dynamic, dynamic> map) async {
  try {
    final DecodeImageEvent event = DecodeImageEvent.fromMap(map);

    var pixels = Uint8List(event.width * event.height);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = _getLuminanceSourcePixel(event.image, i * 4);
    }

    final source = RGBLuminanceSource.orig(
      event.width,
      event.height,
      pixels,
    );

    var bitmap = BinaryBitmap(
      HybridBinarizer(event.invert ? source.invert() : source),
    );

    final reader = QRCodeDartScanMultiReader(event.formats);
    try {
      return reader.decode(bitmap);
    } catch (_) {
      return null;
    }
  } catch (e) {
    // ignore: avoid_print
    print('ERROR:$e');
  }
  return null;
}

Future<ui.Image> decodeImageFromList(Uint8List bytes) {
  Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(bytes, (image) => completer.complete(image));
  return completer.future;
}

int _getLuminanceSourcePixel(List<int> byte, int index) {
  if (byte.length <= index + 3) {
    return 0xff;
  }
  final r = byte[index] & 0xff; // red
  final g2 = (byte[index + 1] << 1) & 0x1fe; // 2 * green
  final b = byte[index + 2]; // blue
  // Calculate green-favouring average cheaply
  return ((r + g2 + b) ~/ 4);
}

LuminanceSource transformToLuminanceSource(List<Plane> planes) {
  final e = planes.first;
  final width = e.bytesPerRow;
  final height = (e.bytes.length / width).round();
  final total = planes
      .map<double>((p) => p.bytesPerPixel!.toDouble())
      .reduce((value, element) => value + 1 / element)
      .toInt();
  final data = Uint8List(width * height * total);
  int startIndex = 0;
  for (var p in planes) {
    List.copyRange(data, startIndex, p.bytes);
    startIndex += width * height ~/ p.bytesPerPixel!;
  }

  return PlanarYUVLuminanceSource(
    data,
    width,
    height,
  );
}
