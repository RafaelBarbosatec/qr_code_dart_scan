import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';

abstract class CroppingStrategy {
  CropRect getCropRect(double width, double height);

  static CroppingStrategy cropCenterSquare({double squareSizeFactor = 1.0}) => CropCenterSquare(
        squareSizeFactor: squareSizeFactor,
      );

  static CroppingStrategy cropReductionMinorAxis({double reductionHeightFactor = 1.0}) =>
      CropReductionMinorAxis(
        reductionHeightFactor: reductionHeightFactor,
      );
}

class CropCenterSquare extends CroppingStrategy {
  final double squareSizeFactor;
  CropCenterSquare({this.squareSizeFactor = 1.0})
      : assert(squareSizeFactor > 0 && squareSizeFactor <= 1,
            'squareSizeFactor must be between 0 and 1');
  @override
  CropRect getCropRect(double width, double height) {
    if (width > height) {
      double squareSize = height * squareSizeFactor;
      double top = (height - squareSize) / 2;
      double left = (width - squareSize) / 2;
      return CropRect.fromLTWH(left, top, squareSize, squareSize);
    } else {
      double squareSize = width * squareSizeFactor;
      double top = (height - squareSize) / 2;
      double left = (width - squareSize) / 2;
      return CropRect.fromLTWH(left, top, squareSize, squareSize);
    }
  }
}

class CropReductionMinorAxis extends CroppingStrategy {
  final double reductionHeightFactor;
  CropReductionMinorAxis({this.reductionHeightFactor = 1.0})
      : assert(reductionHeightFactor > 0 && reductionHeightFactor <= 1,
            'reductionHeightFactor must be between 0 and 1');
  @override
  CropRect getCropRect(double width, double height) {
    if (width > height) {
      double reductionHeight = height * reductionHeightFactor;
      double top = (height - reductionHeight) / 2;
      return CropRect.fromLTWH(0, top, width, reductionHeight);
    } else {
      double reductionWidth = width * reductionHeightFactor;
      double left = (width - reductionWidth) / 2;
      return CropRect.fromLTWH(left, 0, reductionWidth, height);
    }
  }
}
