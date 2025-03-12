import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:test/test.dart';

void main() {
  group('Yuv420Planes', () {
    test('constructor creates instance with required parameters', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final planes = Yuv420Planes(
        bytes: bytes,
        bytesPerRow: 10,
      );

      expect(planes.bytes, bytes);
      expect(planes.bytesPerRow, 10);
      expect(planes.bytesPerPixel, null);
      expect(planes.height, null);
      expect(planes.width, null);
    });

    test('constructor creates instance with all parameters', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final planes = Yuv420Planes(
        bytes: bytes,
        bytesPerRow: 10,
        bytesPerPixel: 2,
        height: 100,
        width: 200,
      );

      expect(planes.bytes, bytes);
      expect(planes.bytesPerRow, 10);
      expect(planes.bytesPerPixel, 2);
      expect(planes.height, 100);
      expect(planes.width, 200);
    });

    group('toMap', () {
      test('converts all properties to map correctly', () {
        final bytes = Uint8List.fromList([1, 2, 3]);
        final planes = Yuv420Planes(
          bytes: bytes,
          bytesPerRow: 10,
          bytesPerPixel: 2,
          height: 100,
          width: 200,
        );

        final map = planes.toMap();

        expect(map['bytes'], bytes.toList());
        expect(map['bytesPerRow'], 10);
        expect(map['bytesPerPixel'], 2);
        expect(map['height'], 100);
        expect(map['width'], 200);
      });

      test('handles null values correctly', () {
        final bytes = Uint8List.fromList([1, 2, 3]);
        final planes = Yuv420Planes(
          bytes: bytes,
          bytesPerRow: 10,
        );

        final map = planes.toMap();

        expect(map['bytes'], bytes.toList());
        expect(map['bytesPerRow'], 10);
        expect(map['bytesPerPixel'], null);
        expect(map['height'], null);
        expect(map['width'], null);
      });
    });

    group('fromMap', () {
      test('creates instance from map with all properties', () {
        final map = {
          'bytes': [1, 2, 3],
          'bytesPerRow': 10,
          'bytesPerPixel': 2,
          'height': 100,
          'width': 200,
        };

        final planes = Yuv420Planes.fromMap(map);

        expect(planes.bytes, Uint8List.fromList([1, 2, 3]));
        expect(planes.bytesPerRow, 10);
        expect(planes.bytesPerPixel, 2);
        expect(planes.height, 100);
        expect(planes.width, 200);
      });

      test('creates instance from map with null values', () {
        final map = {
          'bytes': [1, 2, 3],
          'bytesPerRow': 10,
          'bytesPerPixel': null,
          'height': null,
          'width': null,
        };

        final planes = Yuv420Planes.fromMap(map);

        expect(planes.bytes, Uint8List.fromList([1, 2, 3]));
        expect(planes.bytesPerRow, 10);
        expect(planes.bytesPerPixel, null);
        expect(planes.height, null);
        expect(planes.width, null);
      });
    });

    test('round trip conversion works correctly', () {
      final original = Yuv420Planes(
        bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        bytesPerRow: 15,
        bytesPerPixel: 3,
        height: 120,
        width: 240,
      );

      final map = original.toMap();
      final reconstructed = Yuv420Planes.fromMap(map);

      expect(reconstructed.bytes, original.bytes);
      expect(reconstructed.bytesPerRow, original.bytesPerRow);
      expect(reconstructed.bytesPerPixel, original.bytesPerPixel);
      expect(reconstructed.height, original.height);
      expect(reconstructed.width, original.width);
    });
  });
}
