import 'dart:convert';
import 'dart:io';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:test/test.dart';

void main() {
  const testImageBase64 =
      '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';
  const testResult =
      '00020126480014br.gov.bcb.pix0126rafaelbarbosatec@gmail.com5204000053039865802BR5903PIX6006Cidade62070503***63046BE7';
  late QrCodeDartDecoder decoder;
  setUp(() {
    decoder = QrCodeDartDecoder();
  });

  test('decodeFile', () async {
    final bytes = base64Decode(testImageBase64);
    final result = await decoder.decodeFile(bytes);
    expect(result, isNotNull);
    expect(result?.text, testResult);
    expect(result?.barcodeFormat, BarcodeFormat.qrCode);
  });

   test('decodeFile: should not find ', () async {
    decoder = QrCodeDartDecoder(
      formats: [BarcodeFormat.itf],
    );
    final bytes = base64Decode(testImageBase64);
    final result = await decoder.decodeFile(bytes);
    expect(result, isNull);
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
}
