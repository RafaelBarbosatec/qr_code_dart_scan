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
class QRCodeDartScanController {
  CameraController? _cameraController;

  void configure(CameraController controller) {
    _cameraController = controller;
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
}
