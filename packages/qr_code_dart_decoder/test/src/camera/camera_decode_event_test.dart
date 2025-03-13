import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/camera/camera_decode_event.dart';
import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:test/test.dart';
import 'package:zxing_lib/zxing.dart';

void main() {
  final testYuv420Planes = [
    Yuv420Planes(
      width: 100,
      height: 100,
      bytes: Uint8List.fromList(List.filled(100 * 100, 0)),
      bytesPerRow: 100,
    ),
  ];

  group('CameraDecodeEvent', () {
    test('constructor creates instance with correct values', () {
      final event = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotate: true,
        formats: [BarcodeFormat.qrCode],
      );

      expect(event.yuv420Planes, equals(testYuv420Planes));
      expect(event.invert, isTrue);
      expect(event.rotate, isTrue);
      expect(event.formats, equals([BarcodeFormat.qrCode]));
    });

    test('constructor uses default values when not specified', () {
      final event = CameraDecodeEvent(yuv420Planes: testYuv420Planes);

      expect(event.yuv420Planes, equals(testYuv420Planes));
      expect(event.invert, isFalse);
      expect(event.rotate, isFalse);
      expect(event.formats, isEmpty);
    });

    test('copyWith returns new instance with updated values', () {
      final event = CameraDecodeEvent(yuv420Planes: testYuv420Planes);
      final newYuv420Planes = [
        Yuv420Planes(
          width: 200,
          height: 200,
          bytes: Uint8List.fromList(List.filled(200 * 200, 0)),
          bytesPerRow: 200,
        ),
      ];

      final updatedEvent = event.copyWith(
        invert: true,
        rotate: true,
        yuv420Planes: newYuv420Planes,
        formats: [BarcodeFormat.qrCode, BarcodeFormat.aztec],
      );

      expect(updatedEvent.invert, isTrue);
      expect(updatedEvent.rotate, isTrue);
      expect(updatedEvent.yuv420Planes, equals(newYuv420Planes));
      expect(updatedEvent.formats, equals([BarcodeFormat.qrCode, BarcodeFormat.aztec]));

      // Original should remain unchanged
      expect(event.invert, isFalse);
      expect(event.rotate, isFalse);
      expect(event.yuv420Planes, equals(testYuv420Planes));
      expect(event.formats, isEmpty);
    });

    test('copyWith keeps original values when parameters are null', () {
      final event = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotate: true,
        formats: [BarcodeFormat.qrCode],
      );

      final updatedEvent = event.copyWith();

      expect(updatedEvent.invert, isTrue);
      expect(updatedEvent.rotate, isTrue);
      expect(updatedEvent.yuv420Planes, equals(testYuv420Planes));
      expect(updatedEvent.formats, equals([BarcodeFormat.qrCode]));
    });

    test('toMap converts instance to map correctly', () {
      final event = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotate: true,
      );

      final map = event.toMap();

      expect(map['invert'], isTrue);
      expect(map['rotate'], isTrue);
      expect(map['yuv420Planes'], isA<List>());
      expect(map['yuv420Planes'].length, equals(1));
    });

    test('fromMap creates instance from map correctly', () {
      final originalEvent = CameraDecodeEvent(
        yuv420Planes: testYuv420Planes,
        invert: true,
        rotate: true,
      );

      final map = originalEvent.toMap();
      final recreatedEvent = CameraDecodeEvent.fromMap(map);

      expect(recreatedEvent.invert, isTrue);
      expect(recreatedEvent.rotate, isTrue);
      expect(recreatedEvent.yuv420Planes.length, equals(1));

      // Note: formats is missing in fromMap implementation
      expect(recreatedEvent.formats, isEmpty);
    });
  });
}
