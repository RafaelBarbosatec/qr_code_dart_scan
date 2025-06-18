import 'dart:convert';
import 'dart:io';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:test/test.dart';

void main() {
  const testResult =
      '00020126480014br.gov.bcb.pix0126rafaelbarbosatec@gmail.com5204000053039865802BR5903PIX6006Cidade62070503***63046BE7';

  late QrCodeDartDecoder decoder;
  setUp(() {
    decoder = QrCodeDartDecoder();
  });

  group('QRCode', () {
    test('decodeFile', () async {
      final file = File('test/qr_codes/with_quite_zone.png');
      final bytes = await file.readAsBytes();
      final result = await decoder.decodeFile(bytes);
      expect(result, isNotNull);
      expect(result?.text, testResult);
      expect(result?.barcodeFormat, BarcodeFormat.qrCode);
    });

    test('decodeFile: should not find ', () async {
      decoder = QrCodeDartDecoder(
        formats: [BarcodeFormat.itf],
      );
      final file = File('test/qr_codes/with_quite_zone.png');
      final bytes = await file.readAsBytes();
      final result = await decoder.decodeFile(bytes);
      expect(result, isNull);
    });

    test('decodeFile qrcode without border', () async {
      final file = File('test/qr_codes/without_quite_zone.png');
      final bytes = await file.readAsBytes();
      final result = await decoder.decodeFile(bytes);
      expect(result, isNotNull);
      expect(result?.text, isNotEmpty);
      expect(result?.barcodeFormat, BarcodeFormat.qrCode);
    });

    test('decodeFile qrcode without border black background', () async {
      final file = File('test/qr_codes/without_quite_zone_black_background.png');
      final bytes = await file.readAsBytes();
      final result = await decoder.decodeFile(bytes);
      expect(result, isNotNull);
      expect(result?.text, isNotEmpty);
      expect(result?.barcodeFormat, BarcodeFormat.qrCode);
    });

    test('decodeFile qrcode without border black background2', () async {
      final file = File('test/qr_codes/without_border_2.png');
      final bytes = await file.readAsBytes();
      final result = await decoder.decodeFile(bytes);
      expect(result, isNotNull);
      expect(result?.text, isNotEmpty);
      expect(result?.barcodeFormat, BarcodeFormat.qrCode);
    });

    test('decodeCameraImage', () async {
      final file = File('test/fixtures/plane_qrcode.json');
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);
      final yuv420Planes = (jsonData as List)
          .map(
            (e) => Yuv420Planes.fromMap(
              (e as Map).cast(),
            ),
          )
          .toList();

      final result = await decoder.decodeCameraImage(yuv420Planes);
      expect(result, isNotNull);
      expect(result?.text, isNotNull);
      expect(result?.barcodeFormat, BarcodeFormat.qrCode);
    });

    test('decodeCameraImage: should not find', () async {
      decoder = QrCodeDartDecoder(
        formats: [BarcodeFormat.itf],
      );
      final file = File('test/fixtures/plane_qrcode.json');
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);
      final yuv420Planes = (jsonData as List)
          .map(
            (e) => Yuv420Planes.fromMap(
              (e as Map).cast(),
            ),
          )
          .toList();

      final result = await decoder.decodeCameraImage(yuv420Planes);
      expect(result, isNull);
    });
  });

  group('Itf', () {
    test('decodeBoleto', () async {
      decoder = QrCodeDartDecoder();
      final file = File('test/boleto/boleto.png');
      final bytes = await file.readAsBytes();
      final result = await decoder.decodeFile(bytes);
      expect(result, isNotNull);
      expect(result?.text, '00004000000000000060000000000000000000000000');
      expect(result?.barcodeFormat, BarcodeFormat.itf);
    });

    test('decodeBoleto rotated', () async {
      decoder = QrCodeDartDecoder();
      final file = File('test/boleto/boleto_rotated.png');
      final bytes = await file.readAsBytes();
      final result = await decoder.decodeFile(bytes, rotate: RotationType.counterClockwise);
      expect(result, isNotNull);
      expect(result?.text, '00004000000000000060000000000000000000000000');
      expect(result?.barcodeFormat, BarcodeFormat.itf);
    });
  });
}
