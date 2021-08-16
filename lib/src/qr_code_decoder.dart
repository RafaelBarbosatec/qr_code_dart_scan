import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/zxing2.dart';

import 'extensions.dart';

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
/// on 12/08/21

class DecodeEvent {
  final bool invert;
  final CameraImage cameraImage;

  DecodeEvent({required this.cameraImage, this.invert = false});
  DecodeEvent.fromMap(Map map)
      : invert = map['invert'] as bool,
        cameraImage = CameraImage.fromPlatformData(
          map['image'] as Map<dynamic, dynamic>,
        );

  Map toMap() {
    return {
      'invert': invert,
      'image': cameraImage.toPlatformData(),
    };
  }

  DecodeEvent copyWith({
    bool? invert,
    CameraImage? cameraImage,
  }) {
    return DecodeEvent(
      invert: invert ?? this.invert,
      cameraImage: cameraImage ?? this.cameraImage,
    );
  }
}

Result? decode(Map<dynamic, dynamic> data) {
  try {
    final DecodeEvent event = DecodeEvent.fromMap(data);
    imglib.Image img;
    if (event.cameraImage.format.group == ImageFormatGroup.yuv420) {
      img = _convertYUV420(event.cameraImage);
    } else if (event.cameraImage.format.group == ImageFormatGroup.bgra8888) {
      img = _convertBGRA8888(event.cameraImage);
    } else {
      return null;
    }

    LuminanceSource source = RGBLuminanceSource(
      img.width,
      img.height,
      img.getBytes().buffer.asInt32List(),
    );
    var bitmap = BinaryBitmap(
      HybridBinarizer(event.invert ? source.invert() : source),
    );

    var reader = QRCodeReader();
    try {
      return reader.decode(
        bitmap,
      );
    } catch (_) {
      return null;
    }
  } catch (e) {
    print('>>>>>>>>>>>> ERROR:$e');
  }
  return null;
}

// CameraImage BGRA8888 -> PNG
// Color
imglib.Image _convertBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    image.width,
    image.height,
    image.planes[0].bytes,
    format: imglib.Format.bgra,
  );
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
imglib.Image _convertYUV420(CameraImage image) {
  var img = imglib.Image(image.width, image.height); // Create Image buffer

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
