import 'dart:async';
import 'dart:math';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Minimal in-memory [CameraPlatform] used to exercise the controller's
/// lifecycle without a real device.
class FakeCameraPlatform extends CameraPlatform {
  FakeCameraPlatform();

  static const CameraDescription backCamera = CameraDescription(
    name: 'back',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );

  static const CameraDescription frontCamera = CameraDescription(
    name: 'front',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 270,
  );

  int _nextCameraId = 1;

  /// Camera ids created and not yet disposed.
  final Set<int> openCameras = <int>{};

  /// Camera ids for which [onStreamedFrameAvailable] was subscribed.
  final List<int> startedStreams = <int>[];

  /// Camera ids that were disposed, in order.
  final List<int> disposedCameras = <int>[];

  /// When set, [initializeCamera] waits on it, letting a test interleave a
  /// dispose in the middle of the initialization.
  Completer<void>? initializeGate;

  /// When true, [onStreamedFrameAvailable] fails the way the native side does.
  bool failImageStream = false;

  final Map<int, StreamController<CameraInitializedEvent>> _initializedEvents =
      <int, StreamController<CameraInitializedEvent>>{};

  // `CameraController.initialize` calls `.first` on this stream, which throws
  // `StateError` on an already-closed/empty stream. Keep it open forever.
  final StreamController<CameraErrorEvent> _errorEvents =
      StreamController<CameraErrorEvent>.broadcast();

  final StreamController<CameraImageData> _frames =
      StreamController<CameraImageData>.broadcast();

  @override
  Future<List<CameraDescription>> availableCameras() async {
    return const <CameraDescription>[backCamera, frontCamera];
  }

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async {
    final int id = _nextCameraId++;
    openCameras.add(id);
    _initializedEvents[id] =
        StreamController<CameraInitializedEvent>.broadcast();
    return id;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    final Completer<void>? gate = initializeGate;
    if (gate != null) {
      await gate.future;
    }
    _initializedEvents[cameraId]?.add(
      CameraInitializedEvent(
        cameraId,
        1280,
        720,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ),
    );
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    return _initializedEvents[cameraId]!.stream;
  }

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => _errorEvents.stream;

  @override
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) =>
      const Stream<CameraClosingEvent>.empty();

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream<DeviceOrientationChangedEvent>.empty();

  @override
  Future<void> lockCaptureOrientation(
    int cameraId,
    DeviceOrientation orientation,
  ) async {}

  @override
  Future<void> setFocusMode(int cameraId, FocusMode mode) async {}

  @override
  Future<void> setFocusPoint(int cameraId, Point<double>? point) async {}

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}

  @override
  bool supportsImageStreaming() => true;

  @override
  Stream<CameraImageData> onStreamedFrameAvailable(
    int cameraId, {
    CameraImageStreamOptions? options,
  }) {
    if (failImageStream) {
      throw PlatformException(
        code: 'Disposed CameraController',
        message: 'startImageStream() was called on a disposed CameraController.',
      );
    }
    startedStreams.add(cameraId);
    // Must stay open: a closed/empty stream makes the subscription complete
    // immediately, which deadlocks `stopImageStream()` under fake async.
    return _frames.stream;
  }

  @override
  Widget buildPreview(int cameraId) => const SizedBox.shrink();

  @override
  Future<void> dispose(int cameraId) async {
    openCameras.remove(cameraId);
    disposedCameras.add(cameraId);
  }
}
