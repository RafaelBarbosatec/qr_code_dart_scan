import 'dart:typed_data';

import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';
import 'package:qr_code_dart_decoder/src/util/rotation_type.dart';
import 'package:zxing_lib/zxing.dart';

import 'crop_rect.dart';

abstract class LiminanceMapper {
  static LuminanceSource toLuminanceSource(
    List<Yuv420Planes> planes, {
    RotationType? rotationType,
    CropRect? cropRect,
  }) {
    // Otimização: Para YUV420, apenas o Y plane (primeiro plane) contém
    // a informação de luminância necessária para decodificar QR/barcodes.
    // Não precisamos processar os planes U e V (crominância).
    final yPlane = planes.first;
    int width = yPlane.bytesPerRow;
    int height = (yPlane.bytes.length / width).round();

    // Usa diretamente os bytes do Y plane sem alocação extra
    Uint8List data = yPlane.bytes;

    if (rotationType != null) {
      // Só aloca novo buffer se rotação for necessária
      switch (rotationType) {
        case RotationType.clockwise:
          data = _rotateClockWise(width, height, data);
          final temp = width;
          width = height;
          height = temp;
          break;
        case RotationType.counterClockwise:
          data = _rotateCounterClockWise(width, height, data);
          final temp = width;
          width = height;
          height = temp;
          break;
      }
    }

    LuminanceSource luminanceSource = RGBLuminanceSource.orig(
      width,
      height,
      data,
    );

    if (cropRect != null) {
      luminanceSource = luminanceSource.crop(
        cropRect.left.round(),
        cropRect.top.round(),
        cropRect.width.round(),
        cropRect.height.round(),
      );
    }

    return luminanceSource;
  }

  /// Otimizado: Rotação anti-horária usando processamento por blocos
  /// Melhor cache locality processando blocos de 32x32 pixels
  static Uint8List _rotateCounterClockWise(
    int width,
    int height,
    Uint8List data,
  ) {
    final rotatedData = Uint8List(width * height);
    const blockSize = 32;

    // Processa imagem em blocos para melhor uso de cache
    for (int blockY = 0; blockY < height; blockY += blockSize) {
      final blockHeight = (blockY + blockSize > height) ? height - blockY : blockSize;

      for (int blockX = 0; blockX < width; blockX += blockSize) {
        final blockWidth = (blockX + blockSize > width) ? width - blockX : blockSize;

        // Processa pixels dentro do bloco
        for (int y = 0; y < blockHeight; y++) {
          final sourceY = blockY + y;
          final sourceRowStart = sourceY * width + blockX;
          final targetCol = height - sourceY - 1;

          for (int x = 0; x < blockWidth; x++) {
            rotatedData[(blockX + x) * height + targetCol] = data[sourceRowStart + x];
          }
        }
      }
    }
    return rotatedData;
  }

  /// Otimizado: Rotação horária usando processamento por blocos
  /// Melhor cache locality processando blocos de 32x32 pixels
  static Uint8List _rotateClockWise(
    int width,
    int height,
    Uint8List data,
  ) {
    final rotatedData = Uint8List(width * height);
    const blockSize = 32;

    // Processa imagem em blocos para melhor uso de cache
    for (int blockY = 0; blockY < height; blockY += blockSize) {
      final blockHeight = (blockY + blockSize > height) ? height - blockY : blockSize;

      for (int blockX = 0; blockX < width; blockX += blockSize) {
        final blockWidth = (blockX + blockSize > width) ? width - blockX : blockSize;

        // Processa pixels dentro do bloco
        for (int y = 0; y < blockHeight; y++) {
          final sourceY = blockY + y;
          final sourceRowStart = sourceY * width + blockX;

          for (int x = 0; x < blockWidth; x++) {
            final targetRow = (width - (blockX + x) - 1) * height;
            rotatedData[targetRow + sourceY] = data[sourceRowStart + x];
          }
        }
      }
    }
    return rotatedData;
  }

  static LuminanceSource toLuminanceSourceFromBytes(
    Uint8List imageBytes,
    int width,
    int height, {
    RotationType? rotationType,
    CropRect? cropRect,
  }) {
    final int pixelCount = width * height;
    Uint8List pixels = Uint8List(pixelCount);

    for (int i = 0, j = 0; i < pixelCount; i++, j += 4) {
      pixels[i] = _getLuminanceSourcePixel(imageBytes, j);
    }

    if (rotationType != null) {
      switch (rotationType) {
        case RotationType.clockwise:
          Uint8List rotatedData = _rotateClockWise(width, height, pixels);
          final temp = width;
          width = height;
          height = temp;
          pixels = rotatedData;
          break;
        case RotationType.counterClockwise:
          Uint8List rotatedData = _rotateCounterClockWise(width, height, pixels);
          final temp = width;
          width = height;
          height = temp;
          pixels = rotatedData;
          break;
      }
    }

    LuminanceSource luminanceSource = RGBLuminanceSource.orig(
      width,
      height,
      pixels,
    );

    if (cropRect != null) {
      luminanceSource = luminanceSource.crop(
        cropRect.left.round(),
        cropRect.top.round(),
        cropRect.width.round(),
        cropRect.height.round(),
      );
    }

    return luminanceSource;
  }

  static int _getLuminanceSourcePixel(
    List<int> byte,
    int index,
  ) {
    if (byte.length <= index + 3) {
      return 0xff;
    }
    final r = byte[index] & 0xff; // red
    final g2 = (byte[index + 1] << 1) & 0x1fe; // 2 * green
    final b = byte[index + 2]; // blue
    // Calculate green-favouring average cheaply
    return ((r + g2 + b) ~/ 4);
  }
}
