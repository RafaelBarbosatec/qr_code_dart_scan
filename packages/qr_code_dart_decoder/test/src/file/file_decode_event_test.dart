import 'dart:typed_data';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('FileDecodeEvent', () {
    final testImage = Uint8List.fromList([1, 2, 3, 4]);
    final testFormats = [BarcodeFormat.qrCode, BarcodeFormat.codabar];

    test('constructor creates instance with correct values', () {
      final event = FileDecodeEvent(
        image: testImage,
        invert: true,
        formats: testFormats,
        width: 100,
        height: 200,
      );

      expect(event.image, equals(testImage));
      expect(event.invert, isTrue);
      expect(event.formats, equals(testFormats));
      expect(event.width, equals(100));
      expect(event.height, equals(200));
    });

    test('constructor uses default values when not provided', () {
      final event = FileDecodeEvent(image: testImage);

      expect(event.image, equals(testImage));
      expect(event.invert, isFalse);
      expect(event.formats, isEmpty);
      expect(event.width, equals(0));
      expect(event.height, equals(0));
    });

    test('fromMap creates instance with correct values', () {
      final map = {
        'invert': true,
        'image': testImage,
        'width': 100,
        'height': 200,
        'formats': [BarcodeFormat.qrCode.index, BarcodeFormat.codabar.index],
      };

      final event = FileDecodeEvent.fromMap(map);

      expect(event.image, equals(testImage));
      expect(event.invert, isTrue);
      expect(event.formats.length, equals(2));
      expect(event.formats[0], equals(BarcodeFormat.qrCode));
      expect(event.formats[1], equals(BarcodeFormat.codabar));
      expect(event.width, equals(100));
      expect(event.height, equals(200));
    });

    test('toMap returns correct map representation', () {
      final event = FileDecodeEvent(
        image: testImage,
        invert: true,
        formats: testFormats,
        width: 100,
        height: 200,
      );

      final map = event.toMap();

      expect(map['image'], equals(testImage));
      expect(map['invert'], isTrue);
      expect(map['formats'], equals([BarcodeFormat.qrCode.index, BarcodeFormat.codabar.index]));
      expect(map['width'], equals(100));
      expect(map['height'], equals(200));
    });

    test('copyWith returns new instance with updated values', () {
      final event = FileDecodeEvent(
        image: testImage,
        invert: false,
        formats: [BarcodeFormat.qrCode],
        width: 100,
        height: 200,
      );

      final newImage = Uint8List.fromList([5, 6, 7, 8]);
      final newEvent = event.copyWith(
        image: newImage,
        invert: true,
        formats: testFormats,
        width: 300,
        height: 400,
      );

      // Original event should be unchanged
      expect(event.image, equals(testImage));
      expect(event.invert, isFalse);
      expect(event.formats, equals([BarcodeFormat.qrCode]));
      expect(event.width, equals(100));
      expect(event.height, equals(200));

      // New event should have updated values
      expect(newEvent.image, equals(newImage));
      expect(newEvent.invert, isTrue);
      expect(newEvent.formats, equals(testFormats));
      expect(newEvent.width, equals(300));
      expect(newEvent.height, equals(400));
    });

    test('copyWith keeps original values when not specified', () {
      final event = FileDecodeEvent(
        image: testImage,
        invert: true,
        formats: testFormats,
        width: 100,
        height: 200,
      );

      final newEvent = event.copyWith(width: 300);

      expect(newEvent.image, equals(testImage));
      expect(newEvent.invert, isTrue);
      expect(newEvent.formats, equals(testFormats));
      expect(newEvent.width, equals(300)); // Only this should change
      expect(newEvent.height, equals(200));
    });
  });
}
