import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:test/test.dart';

void main() {
  test('crop center square', () {
    final cropRect = CropCenterSquare().getCropRect(100, 100);
    expect(cropRect.width, 100);
    expect(cropRect.height, 100);
    final cropRect2 = CropCenterSquare().getCropRect(100, 50);
    expect(cropRect2.width, 50);
    expect(cropRect2.height, 50);
    final cropRect3 = CropCenterSquare().getCropRect(50, 100);
    expect(cropRect3.width, 50);
    expect(cropRect3.height, 50);
  });

  test('crop center square with square size factor', () {
    final cropRect = CropCenterSquare(squareSizeFactor: 0.8).getCropRect(100, 100);
    expect(cropRect.width, 80);
    expect(cropRect.height, 80);
    final cropRect2 = CropCenterSquare(squareSizeFactor: 0.8).getCropRect(100, 50);
    expect(cropRect2.top, 5);
    expect(cropRect2.left, 30);
    expect(cropRect2.width, 40);
    expect(cropRect2.height, 40);
    final cropRect3 = CropCenterSquare(squareSizeFactor: 0.8).getCropRect(50, 100);
    expect(cropRect3.top, 30);
    expect(cropRect3.left, 5);
    expect(cropRect3.width, 40);
    expect(cropRect3.height, 40);
  });

  test('crop reduction minor axis', () {
    final cropRect = CropReductionMinorAxis().getCropRect(100, 100);
    expect(cropRect.width, 100);
    expect(cropRect.height, 100);
    final cropRect2 = CropReductionMinorAxis().getCropRect(100, 50);
    expect(cropRect2.width, 100);
    expect(cropRect2.height, 50);
  });

  test('crop reduction minor axis with reduction height factor', () {
    final cropRect = CropReductionMinorAxis(reductionHeightFactor: 0.8).getCropRect(50, 100);
    expect(cropRect.width, 40);
    expect(cropRect.height, 100);
    final cropRect2 = CropReductionMinorAxis(reductionHeightFactor: 0.8).getCropRect(100, 50);
    expect(cropRect2.width, 100);
    expect(cropRect2.height, 40);
  });
}
