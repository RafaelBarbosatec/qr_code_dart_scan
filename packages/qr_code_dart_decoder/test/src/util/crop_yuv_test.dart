import 'dart:convert';
import 'dart:io';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:test/test.dart';

void main() {
  test('crop yuv', () async {
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
    double width = yuv420Planes.first.bytesPerRow.toDouble();
    double height = (yuv420Planes.first.bytes.length / width).round().toDouble();
    final cropRect = CropCenterSquare().getCropRect(width, height);
    final croppedYuv420Planes = CropYuv.cropYuv(yuv420Planes, cropRect);
    int newWidth = croppedYuv420Planes.first.bytesPerRow;
    int newHeight = (croppedYuv420Planes.first.bytes.length / newWidth).round();
    expect(newWidth, cropRect.width);
    expect(newHeight, cropRect.width);
  });
}
