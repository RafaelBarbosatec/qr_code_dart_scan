import 'package:flutter/foundation.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/decoder/decode_event.dart';
import 'package:qr_code_dart_scan/src/decoder/global_functions.dart';
import 'package:qr_code_dart_scan/src/decoder/qr_code_dart_scan_multi_reader.dart';
import 'package:zxing_lib/common.dart';

class IsolateDecoder {
  final List<BarcodeFormat> formats;

  IsolateDecoder({this.formats = QRCodeDartScanDecoder.acceptedFormats});

  Future<Result?> decodeFileImage(XFile file, {bool insverted = false}) async {
    final bytes = await file.readAsBytes();

    final image = await myDecodeImageFromList(bytes);

    final event = DecodeImageEvent(
      image: (await image.toByteData())!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
      formats: formats,
      invert: insverted,
    );

    return compute(_decodeImage, event.toMap());
  }

  Future<Result?> decodeCameraImage(
    CameraImage image, {
    bool insverted = false,
  }) async {
    final event = DecodeCameraImageEvent(
      cameraImage: image,
      formats: formats,
      invert: insverted,
    );
    return compute(decodePlanes, event.toMap());
  }
}

Result? decodePlanes(Map<dynamic, dynamic> msg) {
  try {
    DecodeCameraImageEvent event = DecodeCameraImageEvent.fromMap(msg);

    LuminanceSource source = transformToLuminanceSource(
      event.cameraImage.planes,
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
  } catch (_) {
    return null;
  }
}

Future<Result?> _decodeImage(Map<dynamic, dynamic> map) async {
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
    return null;
  }
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
