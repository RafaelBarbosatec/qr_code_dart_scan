// ignore_for_file: public_member_api_docs, sort_constructors_first
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bytes': bytes.toList(),
      'bytesPerPixel': bytesPerPixel,
      'bytesPerRow': bytesPerRow,
      'height': height,
      'width': width,
    };
  }

  factory Yuv420Planes.fromMap(Map<String, dynamic> map) {
    return Yuv420Planes(
      bytes: Uint8List.fromList(map['bytes'] as List<int>),
      bytesPerPixel: map['bytesPerPixel'] != null ? map['bytesPerPixel'] as int : null,
      bytesPerRow: map['bytesPerRow'] as int,
      height: map['height'] != null ? map['height'] as int : null,
      width: map['width'] != null ? map['width'] as int : null,
    );
  }
}
