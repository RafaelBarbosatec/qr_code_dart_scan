// ignore_for_file: avoid_print, unused_element

import 'dart:io';

import 'package:image/image.dart';

import 'image_pre_processor.dart';

/// Enhanced quality processor for degraded QR code images.
///
/// Applies multiple image processing techniques to improve quality:
/// - Upscaling (for better pixel density)
/// - Noise reduction (median filter + gaussian blur)
/// - Contrast enhancement (histogram equalization)
/// - Sharpening (unsharp mask)
/// - Binarization (Otsu's method)
/// - Morphological operations (erosion/dilation)
class EnhancedQualityProcessor extends ImagePreProcessor {
  final bool debug;
  final int noiseReductionRadius;
  final double sharpenAmount;
  final bool applyHistogramEqualization;
  final bool applyContrastStretch;
  final bool applyMorphology;
  final int binarizationWindowSize;
  final double binarizationThresholdFactor;
  final double upscaleFactor;

  EnhancedQualityProcessor({
    this.debug = false,
    this.noiseReductionRadius = 3,
    this.sharpenAmount = 2.0,
    this.applyHistogramEqualization = true,
    this.applyContrastStretch = true,
    this.applyMorphology = true,
    this.binarizationWindowSize = 21,
    this.binarizationThresholdFactor = 0.92,
    this.upscaleFactor = 2.0,
  });

  @override
  Image? process(Image image) {
    if (debug) {
      print('Processing image: ${image.width}x${image.height}');
      _saveDebugImage(image, 'original');
    }

    // Step 0: Upscale image for better pixel density
    var processed = image;
    if (upscaleFactor > 1.0) {
      final newWidth = (image.width * upscaleFactor).round();
      final newHeight = (image.height * upscaleFactor).round();
      processed = copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: Interpolation.cubic,
      );
      if (debug) {
        print('Upscaled to: ${processed.width}x${processed.height}');
        _saveDebugImage(processed, 'upscaled');
      }
    }

    // Step 1: Convert to grayscale for processing
    processed = grayscale(processed);
    if (debug) _saveDebugImage(processed, 'grayscale');

    // Step 2: Heavy noise reduction - use multiple passes
    processed = _medianFilter(processed, radius: 2);
    if (debug) _saveDebugImage(processed, 'median_filtered');

    processed = gaussianBlur(processed, radius: noiseReductionRadius);
    if (debug) _saveDebugImage(processed, 'noise_reduced');

    // Step 3: Contrast enhancement
    if (applyHistogramEqualization) {
      processed = _histogramEqualization(processed);
      if (debug) _saveDebugImage(processed, 'equalized');
    }

    if (applyContrastStretch) {
      processed = _contrastStretch(processed);
      if (debug) _saveDebugImage(processed, 'contrast_stretched');
    }

    // Step 4: Sharpening to enhance edges
    processed = _sharpen(processed, amount: sharpenAmount);
    if (debug) _saveDebugImage(processed, 'sharpened');

    // Step 5: Global Otsu thresholding (better for heavily degraded images)
    processed = _otsuBinarization(processed);
    if (debug) _saveDebugImage(processed, 'binarized_otsu');

    // Step 6: Morphological operations to clean up noise
    if (applyMorphology) {
      processed = _morphologicalOpening(processed);
      if (debug) _saveDebugImage(processed, 'final_morphology');
    }

    return processed;
  }

  /// Applies histogram equalization to enhance contrast
  Image _histogramEqualization(Image image) {
    // Calculate histogram
    final histogram = List<int>.filled(256, 0);
    for (final pixel in image) {
      final luminance = pixel.r.toInt();
      histogram[luminance]++;
    }

    // Calculate cumulative distribution function
    final cdf = List<double>.filled(256, 0);
    cdf[0] = histogram[0].toDouble();
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Normalize CDF
    final cdfMin = cdf.firstWhere((value) => value > 0);
    final totalPixels = (image.width * image.height).toDouble();
    final lookupTable = List<int>.generate(256, (i) {
      if (cdf[i] == 0) return 0;
      return ((cdf[i] - cdfMin) / (totalPixels - cdfMin) * 255).round().clamp(0, 255);
    });

    // Apply lookup table
    final result = Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = pixel.r.toInt();
        final newValue = lookupTable[luminance];
        result.setPixelRgb(x, y, newValue, newValue, newValue);
      }
    }
    return result;
  }

  /// Stretches contrast to use full dynamic range
  Image _contrastStretch(Image image) {
    int min = 255;
    int max = 0;

    // Find min and max values
    for (final pixel in image) {
      final luminance = pixel.r.toInt();
      if (luminance < min) min = luminance;
      if (luminance > max) max = luminance;
    }

    if (max == min) return image;

    // Stretch contrast
    final range = max - min;
    final result = Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = pixel.r.toInt();
        final stretched = ((luminance - min) * 255 / range).round().clamp(0, 255);
        result.setPixelRgb(x, y, stretched, stretched, stretched);
      }
    }
    return result;
  }

  /// Sharpens the image using unsharp mask technique
  Image _sharpen(Image image, {required double amount}) {
    // Create a blurred version
    final blurred = gaussianBlur(image, radius: 1);

    // Sharpen = original + amount * (original - blurred)
    final result = Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final originalLum = pixel.r.toInt();
        final blurredLum = blurred.getPixel(x, y).r.toInt();
        final difference = originalLum - blurredLum;
        final sharpened = (originalLum + amount * difference).round().clamp(0, 255);
        result.setPixelRgb(x, y, sharpened, sharpened, sharpened);
      }
    }
    return result;
  }

  /// Applies adaptive binarization using local threshold (alternative method)
  /// Currently not used in favor of Otsu, but kept for flexibility
  Image _adaptiveBinarization(
    Image image, {
    required int windowSize,
    required double thresholdFactor,
  }) {
    final width = image.width;
    final height = image.height;
    final halfWindow = windowSize ~/ 2;
    final result = Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Calculate local mean in window
        int sum = 0;
        int count = 0;

        for (int dy = -halfWindow; dy <= halfWindow; dy++) {
          for (int dx = -halfWindow; dx <= halfWindow; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              sum += image.getPixel(nx, ny).r.toInt();
              count++;
            }
          }
        }

        final localMean = sum / count;
        final pixel = image.getPixel(x, y);
        final luminance = pixel.r.toInt();

        // Use threshold factor to adjust sensitivity
        final threshold = localMean * thresholdFactor;
        final binarized = luminance > threshold ? 255 : 0;

        result.setPixelRgb(x, y, binarized, binarized, binarized);
      }
    }
    return result;
  }

  /// Applies morphological opening (erosion followed by dilation) to remove noise
  Image _morphologicalOpening(Image image) {
    // Use a very small kernel to preserve QR code structure
    // Erosion: removes small white noise
    final eroded = _erode(image, kernelSize: 1);
    // Dilation: restores the size of objects after erosion
    final dilated = _dilate(eroded, kernelSize: 1);
    return dilated;
  }

  /// Erosion operation - shrinks white regions
  Image _erode(Image image, {int kernelSize = 1}) {
    final width = image.width;
    final height = image.height;
    final result = Image(width: width, height: height);
    final halfKernel = kernelSize ~/ 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Check if all pixels in kernel are white
        bool allWhite = true;
        for (int dy = -halfKernel; dy <= halfKernel && allWhite; dy++) {
          for (int dx = -halfKernel; dx <= halfKernel && allWhite; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              if (image.getPixel(nx, ny).r.toInt() < 128) {
                allWhite = false;
              }
            }
          }
        }
        final value = allWhite ? 255 : 0;
        result.setPixelRgb(x, y, value, value, value);
      }
    }
    return result;
  }

  /// Dilation operation - expands white regions
  Image _dilate(Image image, {int kernelSize = 1}) {
    final width = image.width;
    final height = image.height;
    final result = Image(width: width, height: height);
    final halfKernel = kernelSize ~/ 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Check if any pixel in kernel is white
        bool anyWhite = false;
        for (int dy = -halfKernel; dy <= halfKernel && !anyWhite; dy++) {
          for (int dx = -halfKernel; dx <= halfKernel && !anyWhite; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              if (image.getPixel(nx, ny).r.toInt() > 128) {
                anyWhite = true;
              }
            }
          }
        }
        final value = anyWhite ? 255 : 0;
        result.setPixelRgb(x, y, value, value, value);
      }
    }
    return result;
  }

  /// Applies median filter to remove salt-and-pepper noise
  Image _medianFilter(Image image, {required int radius}) {
    final width = image.width;
    final height = image.height;
    final result = Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final values = <int>[];

        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              values.add(image.getPixel(nx, ny).r.toInt());
            }
          }
        }

        values.sort();
        final median = values[values.length ~/ 2];
        result.setPixelRgb(x, y, median, median, median);
      }
    }
    return result;
  }

  /// Applies Otsu's method for global thresholding
  Image _otsuBinarization(Image image) {
    // Calculate histogram
    final histogram = List<int>.filled(256, 0);
    final totalPixels = image.width * image.height;

    for (final pixel in image) {
      histogram[pixel.r.toInt()]++;
    }

    // Calculate optimal threshold using Otsu's method
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;
    double maxVariance = 0;
    int threshold = 0;

    for (int t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;

      wF = totalPixels - wB;
      if (wF == 0) break;

      sumB += t * histogram[t];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = t;
      }
    }

    if (debug) {
      print('Otsu threshold: $threshold');
    }

    // Apply threshold
    final result = Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = pixel.r.toInt();
        final binarized = luminance > threshold ? 255 : 0;
        result.setPixelRgb(x, y, binarized, binarized, binarized);
      }
    }
    return result;
  }

  void _saveDebugImage(Image image, String suffix) {
    try {
      final filename = 'debug_$suffix.png';
      final pngBytes = encodePng(image);
      final file = File(filename);
      file.writeAsBytes(pngBytes);
      print('Debug image saved to $filename');
    } catch (e) {
      print('Failed to save debug image: $e');
    }
  }
}
