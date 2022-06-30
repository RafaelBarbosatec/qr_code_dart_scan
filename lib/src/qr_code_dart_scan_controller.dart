import 'package:camera/camera.dart';

///
/// Created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 12/08/21

abstract class DartScanInterface {
  void takePictureAndDecode();
}

class QRCodeDartScanController {
  bool _scanEnabled = true;
  CameraController? _cameraController;
  DartScanInterface? _dartScanInterface;

  void configure(
    CameraController cameraController,
    DartScanInterface dartScanInterface,
  ) {
    _cameraController = cameraController;
    _dartScanInterface = dartScanInterface;
  }

  Future<void>? setFlashMode(FlashMode mode) {
    return _cameraController?.setFlashMode(mode);
  }

  Future<void>? setZoomLevel(double zoom) {
    return _cameraController?.setZoomLevel(zoom);
  }

  Future<void>? setFocusMode(FocusMode mode) {
    return _cameraController?.setFocusMode(mode);
  }

  void setScanEnabled(bool enable) {
    _scanEnabled = enable;
  }

  void takePictureAndDecode() => _dartScanInterface?.takePictureAndDecode();

  bool get scanEnabled => _scanEnabled;
}
