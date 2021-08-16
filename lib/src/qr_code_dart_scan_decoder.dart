import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';

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
  final List<BarcodeFormat> formats;

  DecodeEvent(
      {required this.cameraImage,
      this.invert = false,
      List<BarcodeFormat>? formats})
      : this.formats = formats ?? [BarcodeFormat.QR_CODE];
  DecodeEvent.fromMap(Map map)
      : invert = map['invert'] as bool,
        cameraImage = CameraImage.fromPlatformData(
          map['image'] as Map<dynamic, dynamic>,
        ),
        formats = map['formats']
            .map<BarcodeFormat>((f) => BarcodeFormat.values[f])
            .toList();

  Map toMap() {
    return {
      'invert': invert,
      'image': cameraImage.toPlatformData(),
      'formats': formats.map((e) => e.index).toList(),
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
      return reader.decode(bitmap);
    } catch (_) {
      return null;
    }
  } catch (e) {
    print('ERROR:$e');
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

/// This class is used to help decode images from files which arrive as RGB data from
/// an ARGB pixel array. It does not support rotation.
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Betaminos
class RGBLuminanceSource extends LuminanceSource {
  late final Int8List _luminances;
  final int _dataWidth;
  final int _dataHeight;
  final int _left;
  final int _top;

  RGBLuminanceSource(this._dataWidth, this._dataHeight, Int32List pixels)
      : _left = 0,
        _top = 0,
        super(_dataWidth, _dataHeight) {
    // In order to measure pure decoding speed, we convert the entire image to a greyscale array
    // up front, which is the same as the Y channel of the YUVLuminanceSource in the real app.
    //
    // Total number of pixels suffices, can ignore shape
    var size = _dataWidth * _dataHeight;
    _luminances = Int8List(size);
    for (var offset = 0; offset < size; offset++) {
      var pixel = pixels[offset];
      var r = (pixel >> 16) & 0xff; // red
      var g2 = (pixel >> 7) & 0x1fe; // 2 * green
      var b = pixel & 0xff; // blue
      // Calculate green-favouring average cheaply
      _luminances[offset] = ((r + g2 + b) ~/ 4).toInt();
    }
  }

  RGBLuminanceSource.crop(Int8List pixels, this._dataWidth, this._dataHeight,
      this._left, this._top, int width, int height)
      : _luminances = pixels,
        super(width, height) {
    if (_left + width > _dataWidth || _top + height > _dataHeight) {
      throw ArgumentError('Crop rectangle does not fit within image data.');
    }
  }

  @override
  Int8List getRow(int y, Int8List? row) {
    if (y < 0 || y >= height) {
      throw ArgumentError('Requested row is outside the image: $y');
    }
    var width = this.width;
    if (row == null || row.length < width) {
      row = Int8List(width);
    }
    var offset = (y + _top) * _dataWidth + _left;
    arraycopy(_luminances, offset, row, 0, width);
    return row;
  }

  @override
  Int8List get matrix {
    var width = this.width;
    var height = this.height;

    // If the caller asks for the entire underlying image, save the copy and give them the
    // original data. The docs specifically warn that result.length must be ignored.
    if (width == _dataWidth && height == _dataHeight) {
      return _luminances;
    }

    var area = width * height;
    var matrix = Int8List(area);
    var inputOffset = _top * _dataWidth + _left;

    // If the width matches the full width of the underlying data, perform a single copy.
    if (width == _dataWidth) {
      arraycopy(_luminances, inputOffset, matrix, 0, area);
      return matrix;
    }

    // Otherwise copy one cropped row at a time.
    for (var y = 0; y < height; y++) {
      var outputOffset = y * width;
      arraycopy(_luminances, inputOffset, matrix, outputOffset, width);
      inputOffset += _dataWidth;
    }
    return matrix;
  }

  @override
  bool get isCropSupported {
    return true;
  }

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return RGBLuminanceSource.crop(_luminances, _dataWidth, _dataHeight,
        _left + left, _top + top, width, height);
  }
}

void arraycopy(List src, int srcPos, List dest, int destPos, int length) {
  dest.setRange(destPos, destPos + length, src, srcPos);
}
