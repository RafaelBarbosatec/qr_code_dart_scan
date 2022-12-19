import 'package:camera/camera.dart';
import 'package:image/image.dart' as img_lib;
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

Result? decode(Map<dynamic, dynamic> data) {
  try {
    final DecodeCameraImageEvent event = DecodeCameraImageEvent.fromMap(data);
    img_lib.Image img;
    if (event.cameraImage.format.group == ImageFormatGroup.yuv420) {
      img = _convertYUV420(event.cameraImage);
    } else if (event.cameraImage.format.group == ImageFormatGroup.bgra8888) {
      img = _convertBGRA8888(event.cameraImage);
    } else {
      return null;
    }

    final source = RGBLuminanceSource(
      img.width,
      img.height,
      img.getBytes().buffer.asInt32List(),
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

Result? decodeImage(Map<dynamic, dynamic> map) {
  try {
    final DecodeImageEvent event = DecodeImageEvent.fromMap(map);

    final image = img_lib.decodeImage(event.image);
    final source = RGBLuminanceSource(
      image?.width ?? 0,
      image?.height ?? 0,
      image?.getBytes().buffer.asInt32List() ?? [],
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

// CameraImage BGRA8888 -> PNG
// Color
img_lib.Image _convertBGRA8888(CameraImage image) {
  return img_lib.Image.fromBytes(
    image.width,
    image.height,
    image.planes[0].bytes,
    format: img_lib.Format.bgra,
  );
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
img_lib.Image _convertYUV420(CameraImage image) {
  var img = img_lib.Image(image.width, image.height); // Create Image buffer

  var plane = image.planes.first;
  const shift = 0xFF << 24;

  // Fill image buffer with plane[0] from YUV420_888
  for (var x = 0; x < image.width; x++) {
    for (var planeOffset = 0;
        planeOffset < image.height * image.width;
        planeOffset += image.width) {
      final pixelColor = plane.bytes[planeOffset + x];
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
      // Calculate pixel color
      var newVal = shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

      img.data[planeOffset + x] = newVal;
    }
  }

  return img;
}
