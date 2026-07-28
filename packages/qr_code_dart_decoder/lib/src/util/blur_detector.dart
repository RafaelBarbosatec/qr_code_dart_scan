import 'package:qr_code_dart_decoder/src/camera/yuv420_planes.dart';

/// Detector de blur para frames de câmera.
/// Usa amostragem para detectar rapidamente se um frame está borrado,
/// evitando processamento desnecessário de frames que não teriam sucesso.
abstract class BlurDetector {
  /// Limite de variância abaixo do qual considera-se blur.
  /// Valores menores = mais sensível a blur
  /// Valores maiores = menos sensível
  static const double _blurThreshold = 100.0;

  /// Tamanho da grade de amostragem (pixels por sample)
  static const int _sampleStep = 16;

  /// Detecta se o frame está borrado usando variância de Laplaciano
  /// em amostras do Y plane.
  ///
  /// Retorna true se a imagem está nítida (pode processar),
  /// false se está borrada (skip recomendado).
  static bool isSharp(List<Yuv420Planes> yuv420Planes) {
    if (yuv420Planes.isEmpty) return false;

    final yPlane = yuv420Planes.first;
    final width = yPlane.bytesPerRow;
    final height = (yPlane.bytes.length / width).round();
    final bytes = yPlane.bytes;

    // Calcula variância usando amostras (Laplacian variance method)
    double sumOfSquares = 0.0;
    int sampleCount = 0;

    // Processa amostras em grade para velocidade
    // Evita bordas (4 pixels) onde pode haver ruído
    for (int y = 4; y < height - 4; y += _sampleStep) {
      for (int x = 4; x < width - 4; x += _sampleStep) {
        // Calcula Laplaciano aproximado (segunda derivada)
        // Kernel simplificado: [-1, 2, -1] horizontal e vertical
        final center = y * width + x;

        if (center + width + 1 >= bytes.length || center - width - 1 < 0) {
          continue;
        }

        final centerValue = bytes[center].toDouble();

        // Laplaciano horizontal: -left + 2*center - right
        final horizontal = -bytes[center - 1] + 2 * centerValue - bytes[center + 1];

        // Laplaciano vertical: -top + 2*center - bottom
        final vertical = -bytes[center - width] + 2 * centerValue - bytes[center + width];

        // Magnitude do gradiente
        final laplacian = (horizontal.abs() + vertical.abs()) / 2;

        sumOfSquares += laplacian * laplacian;
        sampleCount++;
      }
    }

    if (sampleCount == 0) return true;

    // Calcula variância média
    final variance = sumOfSquares / sampleCount;

    // Se variância muito baixa = imagem sem detalhes/borrada
    return variance > _blurThreshold;
  }

  /// Versão simplificada que usa apenas gradientes horizontais
  /// para máxima performance.
  static bool isSharpFast(List<Yuv420Planes> yuv420Planes) {
    if (yuv420Planes.isEmpty) return false;

    final yPlane = yuv420Planes.first;
    final width = yPlane.bytesPerRow;
    final height = (yPlane.bytes.length / width).round();
    final bytes = yPlane.bytes;

    double sumOfSquares = 0.0;
    int sampleCount = 0;

    // Amostragem mais espaçada para máxima velocidade
    for (int y = 8; y < height - 8; y += 32) {
      for (int x = 8; x < width - 8; x += 32) {
        final index = y * width + x;

        if (index + 1 >= bytes.length || index - 1 < 0) {
          continue;
        }

        // Apenas gradiente horizontal (mais rápido)
        final gradient = (bytes[index + 1] - bytes[index - 1]).abs();

        sumOfSquares += gradient * gradient;
        sampleCount++;
      }
    }

    if (sampleCount == 0) return true;

    final variance = sumOfSquares / sampleCount;

    // Threshold ajustado para método simplificado
    return variance > 25.0;
  }
}
