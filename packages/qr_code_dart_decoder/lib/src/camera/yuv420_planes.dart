// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:isolate';
import 'dart:typed_data';

class Yuv420Planes {
  /// Bytes representing this plane.
  final Uint8List bytes;

  /// The distance between adjacent pixel samples on Android, in bytes.
  ///
  /// Will be `null` on iOS.
  final int? bytesPerPixel;

  /// The row stride for this color plane, in bytes.
  final int bytesPerRow;

  /// Height of the pixel buffer on iOS.
  ///
  /// Will be `null` on Android
  final int? height;

  /// Width of the pixel buffer on iOS.
  ///
  /// Will be `null` on Android.
  final int? width;

  Yuv420Planes({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel,
    this.height,
    this.width,
  });

  /// Converts to a transferable representation for efficient isolate communication.
  /// Uses TransferableTypedData for zero-copy transfer between isolates.
  TransferableYuv420Planes toTransferable() {
    return TransferableYuv420Planes(
      bytes: TransferableTypedData.fromList([bytes]),
      bytesPerPixel: bytesPerPixel,
      bytesPerRow: bytesPerRow,
      height: height,
      width: width,
    );
  }

  /// Creates Yuv420Planes from a transferable representation.
  factory Yuv420Planes.fromTransferable(TransferableYuv420Planes transferable) {
    final materializedBytes = transferable.bytes.materialize();
    return Yuv420Planes(
      bytes: materializedBytes.asUint8List(),
      bytesPerPixel: transferable.bytesPerPixel,
      bytesPerRow: transferable.bytesPerRow,
      height: transferable.height,
      width: transferable.width,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bytes': bytes, // Mantém Uint8List diretamente (mais eficiente)
      'bytesPerPixel': bytesPerPixel,
      'bytesPerRow': bytesPerRow,
      'height': height,
      'width': width,
    };
  }

  factory Yuv420Planes.fromMap(Map<String, dynamic> map) {
    final bytesData = map['bytes'];
    return Yuv420Planes(
      bytes: bytesData is Uint8List ? bytesData : Uint8List.fromList((bytesData as List).cast<int>()),
      bytesPerPixel: map['bytesPerPixel'] != null ? map['bytesPerPixel'] as int : null,
      bytesPerRow: map['bytesPerRow'] as int,
      height: map['height'] != null ? map['height'] as int : null,
      width: map['width'] != null ? map['width'] as int : null,
    );
  }
}

/// Efficient class for isolate transfer of YUV plane data using TransferableTypedData.
/// This allows zero-copy transfer of large byte arrays between isolates.
class TransferableYuv420Planes {
  final TransferableTypedData bytes;
  final int? bytesPerPixel;
  final int bytesPerRow;
  final int? height;
  final int? width;

  TransferableYuv420Planes({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel,
    this.height,
    this.width,
  });
}
