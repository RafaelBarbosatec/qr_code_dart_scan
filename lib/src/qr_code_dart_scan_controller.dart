import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/util/extensions.dart';

import 'util/qr_code_dart_scan_config.dart';

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

class PreviewState extends Equatable {
  final Result? result;
  final bool processing;
  final bool initialized;
  final TypeScan typeScan;
  final TypeCamera typeCamera;
  final DeviceOrientation? lockCaptureOrientation;

  const PreviewState({
    this.result,
    this.processing = false,
    this.initialized = false,
    this.typeScan = TypeScan.live,
    this.typeCamera = TypeCamera.back,
    this.lockCaptureOrientation,
  });

  PreviewState copyWith({
    Result? result,
    bool? processing,
    bool? initialized,
    TypeScan? typeScan,
    TypeCamera? typeCamera,
  }) {
    return PreviewState(
      result: result,
      processing: processing ?? this.processing,
      initialized: initialized ?? this.initialized,
      typeScan: typeScan ?? this.typeScan,
      typeCamera: typeCamera ?? this.typeCamera,
    );
  }

  @override
  List<Object?> get props => [
        result,
        processing,
        initialized,
        typeScan,
        typeCamera,
      ];
}

class QRCodeDartScanController {
  final ValueNotifier<PreviewState> state = ValueNotifier(const PreviewState());
  CameraController? cameraController;
  QRCodeDartScanDecoder? _codeDartScanDecoder;
  bool _scanEnabled = false;
  bool get isLiveScan => state.value.typeScan == TypeScan.live && _scanEnabled;
  _LastScan? _lastScan;
  late QRCodeDartScanConfig _config;
  Result? _lastResult;

  Future<void> config(
    QRCodeDartScanConfig config,
  ) async {
    _config = config;
    state.value = state.value.copyWith(
      typeScan: config.typeScan,
    );
    _codeDartScanDecoder = QRCodeDartScanDecoder(
      formats: config.formats,
    );
    _lastScan = _LastScan(
      date: DateTime.now()
        ..subtract(
          const Duration(days: 1),
        ),
    );
    await _initController(config.typeCamera);
  }

  Future<void> _initController(TypeCamera typeCamera) async {
    state.value = state.value.copyWith(
      initialized: false,
      typeCamera: typeCamera,
    );
    final camera = await _getCamera(typeCamera);
    if (camera == null) {
      _config.onCameraError?.call('camera_not_found ($typeCamera)');
      return;
    }
    cameraController = CameraController(
      camera,
      _config.resolutionPreset.toResolutionPreset(),
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
      fps: _config.fps,
      videoBitrate: _config.videoBitrate,
    );

    try {
      await cameraController?.initialize();
      if (_config.focusPoint != null) {
        await cameraController?.setFocusMode(FocusMode.locked);
        await cameraController?.setFocusPoint(_config.focusPoint!);
      }
      if (_config.lockCaptureOrientation != null) {
        cameraController?.lockCaptureOrientation(_config.lockCaptureOrientation!);
      }
    } catch (e) {
      if (e is CameraException) {
        _config.onCameraError?.call(e.code);
      } else {
        _config.onCameraError?.call(e.toString());
      }
      return;
    }

    await startScan();

    state.value = state.value.copyWith(
      initialized: true,
    );
  }

  Future<CameraDescription?> _getCamera(TypeCamera typeCamera) async {
    final CameraLensDirection lensDirection;
    switch (typeCamera) {
      case TypeCamera.back:
        lensDirection = CameraLensDirection.back;
        break;
      case TypeCamera.front:
        lensDirection = CameraLensDirection.front;
        break;
    }

    final cameras = await availableCameras();
    try {
      return cameras.firstWhere(
        (camera) => camera.lensDirection == lensDirection,
      );
    } catch (e) {
      return null;
    }
  }

  void _imageStream(CameraImage image) async {
    if (state.value.processing) return;
    state.value = state.value.copyWith(
      processing: true,
    );
    _processImage(image);
  }

  void _processImage(CameraImage image) async {
    try {
      if (_lastScan?.checkTime(_config.intervalScan) == true) {
        final decoded = await _codeDartScanDecoder?.decodeCameraImage(
          image,
          imageDecodeOrientation: _config.imageDecodeOrientation,
          croppingStrategy: _config.croppingStrategy,
        );
        if (decoded != null) {
          final canNotify = _config.onResultInterceptor?.call(_lastResult, decoded) ?? true;
          if (canNotify == true) {
            _lastResult = decoded;
            state.value = state.value.copyWith(
              result: decoded,
            );
          }
        }
      }
    } catch (e) {
      // Log error but continue processing
      debugPrint('Error processing image: $e');
    } finally {
      // Sempre marca como não processando
      state.value = state.value.copyWith(
        processing: false,
      );
    }
  }

  Future<void> changeTypeScan(TypeScan type) async {
    if (state.value.typeScan == type) {
      return;
    }
    if (type == TypeScan.live) {
      await startScan();
    } else {
      await stopScan();
    }
    state.value = state.value.copyWith(
      processing: false,
      typeScan: type,
    );
  }

  Future<void> stopScan() async {
    if (isLiveScan) {
      await stopImageStream();
      _scanEnabled = false;
    }
  }

  Future<void> startScan() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (state.value.typeScan == TypeScan.live && !_scanEnabled) {
      await cameraController?.startImageStream(_imageStream);
      _scanEnabled = true;
    }
  }

  Future<void> takePictureAndDecode() async {
    if (state.value.processing) return;
    state.value = state.value.copyWith(
      processing: true,
    );
    final xFile = await cameraController?.takePicture();

    if (xFile != null) {
      final decoded = await _codeDartScanDecoder?.decodeFile(
        xFile,
      );
      state.value = state.value.copyWith(
        result: decoded,
      );
    }

    state.value = state.value.copyWith(
      processing: false,
    );
  }

  Future<void> changeCamera(TypeCamera typeCamera) async {
    state.value = const PreviewState();
    await _disposeController();
    await _initController(typeCamera);
  }

  Future<void> dispose() async {
    _codeDartScanDecoder?.dispose();
    state.value = const PreviewState();
    return _disposeController();
  }

  Future<void> _disposeController() async {
    try {
      await stopScan();
      await cameraController?.dispose();
    } catch (e) {
      debugPrint('Error dispose controller: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (cameraController?.value.isStreamingImages == true) {
      await cameraController?.stopImageStream();
    }
  }

  Future<void> setFlashAuto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    try {
      await cameraController?.setFlashMode(
        FlashMode.auto,
      );
    } catch (e) {
      debugPrint('Error setFlashAuto flash: $e');
    }
  }

  Future<void> setFlash(bool on) async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    try {
      await cameraController?.setFlashMode(
        on ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Error setFlash = $on flash: $e');
    }
  }

  bool get isFlashOn => cameraController!.value.flashMode == FlashMode.torch;

  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    await setFlash(!isFlashOn);
  }

  Future<void> setFocusPoint(Offset? point) async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (point == null) {
      await cameraController?.setFocusMode(FocusMode.auto);
      return;
    }
    await cameraController?.setFocusMode(FocusMode.locked);
    await cameraController?.setFocusPoint(point);
  }
}

class _LastScan {
  DateTime date;

  _LastScan({
    required this.date,
  });

  bool checkTime(Duration intervalScan) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMilliseconds < intervalScan.inMilliseconds) {
      return false;
    }
    date = DateTime.now();
    return true;
  }
}
