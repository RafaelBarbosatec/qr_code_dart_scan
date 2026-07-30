import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:qr_code_dart_scan/src/qr_code_dart_scan_controller.dart';
import 'package:qr_code_dart_scan/src/util/extensions.dart';
import 'package:qr_code_dart_scan/src/util/image_decode_orientation.dart';
import 'package:qr_code_dart_scan/src/util/qr_code_dart_scan_resolution_preset.dart';
import 'package:zxing_lib/src/result_point.dart';

import 'decoder/qr_code_dart_scan_decoder.dart';
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

enum TypeCamera { back, front }

enum TypeScan { live, takePicture }

typedef TakePictureButtonBuilder = Widget Function(
  BuildContext context,
  QRCodeDartScanController controller,
  bool loading,
);

class QRCodeDartScanView extends StatefulWidget {
  final TypeCamera typeCamera;
  final TypeScan typeScan;
  final ValueChanged<Result>? onCapture;

  /// Use to limit a specific format
  /// If null use all accepted formats
  /// List of barcode formats to scan for. If null or empty, uses all accepted formats
  final List<BarcodeFormat> formats;

  /// Controller to manage the QR code scanning functionality
  final QRCodeDartScanController? controller;

  /// Resolution preset for the camera preview
  final QRCodeDartScanResolutionPreset resolutionPreset;

  /// Optional child widget to overlay on top of the camera preview
  final Widget? child;

  /// Width of the camera preview
  final double? widthPreview;

  /// Height of the camera preview
  final double? heightPreview;

  /// Builder for customizing the take picture button
  final TakePictureButtonBuilder? takePictureButtonBuilder;

  /// Minimum duration between scans of the same QR code
  final Duration intervalScan;

  /// Callback to intercept and decide if the result should be returned
  final OnResultInterceptorCallback? onResultInterceptor;

  /// Forces a specific device orientation for capturing
  final DeviceOrientation? lockCaptureOrientation;

  /// Controls how the image is oriented during decoding
  final ImageDecodeOrientation imageDecodeOrientation;

  /// Callback when camera errors occur
  final ValueChanged<String>? onCameraError;

  /// Frames per second for the camera preview
  final int? fps;

  /// Video bitrate for the camera preview
  final int? videoBitrate;

  /// Strategy to crop the camera image before decoding
  final CroppingStrategy? croppingStrategy;

  /// Focus point for the camera preview
  final Offset? focusPoint;

  /// Timeout for the image stream
  final Duration imageStreamTimeout;

  const QRCodeDartScanView({
    Key? key,
    this.typeCamera = TypeCamera.back,
    this.typeScan = TypeScan.live,
    this.onCapture,
    this.resolutionPreset = QRCodeDartScanResolutionPreset.medium,
    this.controller,
    this.formats = QRCodeDartScanDecoder.acceptedFormats,
    this.child,
    this.takePictureButtonBuilder,
    this.widthPreview,
    this.heightPreview,
    this.intervalScan = const Duration(milliseconds: 500),
    this.onResultInterceptor,
    this.lockCaptureOrientation = DeviceOrientation.portraitUp,
    this.imageDecodeOrientation = ImageDecodeOrientation.original,
    this.onCameraError,
    this.fps,
    this.videoBitrate,
    this.croppingStrategy,
    this.focusPoint,
    this.imageStreamTimeout = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  QRCodeDartScanViewState createState() => QRCodeDartScanViewState();
}

class QRCodeDartScanViewState extends State<QRCodeDartScanView>
    with WidgetsBindingObserver {
  late QRCodeDartScanController controller;
  bool initialized = false;
  bool _isControllerDisposed = false;
  Key _cameraKey = UniqueKey();
  double _scale = 1.0;
  Size _previewSize = Size.zero;
  Size _cameraSize = Size.zero;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = controller.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive && !_isControllerDisposed) {
      _isControllerDisposed = true;
      stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _isControllerDisposed = false;
      _initController();
    }
    super.didChangeAppLifecycleState(state);
  }

  void stopCamera() {
    setState(() {
      controller.state.removeListener(_onStateListener);
      controller.dispose();
      initialized = false;
    });
  }

  void startCamera() {
    if (initialized) {
      return;
    }
    _initController();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startCamera();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    controller.state.removeListener(_onStateListener);
    controller.dispose();
    _isControllerDisposed = true;
    initialized = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: initialized ? _getCameraWidget(context) : widget.child,
    );
  }

  void _initController() async {
    controller = widget.controller ?? QRCodeDartScanController();
    controller.state.addListener(_onStateListener);
    await controller.config(
      QRCodeDartScanConfig(
        formats: widget.formats,
        typeCamera: widget.typeCamera,
        typeScan: widget.typeScan,
        imageDecodeOrientation: widget.imageDecodeOrientation,
        resolutionPreset: widget.resolutionPreset,
        intervalScan: widget.intervalScan,
        onResultInterceptor: widget.onResultInterceptor,
        lockCaptureOrientation: widget.lockCaptureOrientation,
        onCameraError: widget.onCameraError,
        fps: widget.fps,
        videoBitrate: widget.videoBitrate,
        croppingStrategy: widget.croppingStrategy,
        focusPoint: widget.focusPoint,
        imageStreamTimeout: widget.imageStreamTimeout,
      ),
    );
  }

  Widget _buildButton() {
    return ValueListenableBuilder<PreviewState>(
      valueListenable: controller.state,
      builder: (context, value, child) {
        return widget.takePictureButtonBuilder?.call(
              context,
              controller,
              value.processing,
            ) ??
            _ButtonTakePicture(
              onTakePicture: controller.takePictureAndDecode,
              isLoading: value.processing,
            );
      },
    );
  }

  Widget _getCameraWidget(BuildContext context) {
    final cameraController = controller.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return widget.child ?? const SizedBox.shrink();
    }

    var camera = cameraController.value;
    // fetch screen size
    final size = MediaQuery.of(context).size;

    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    Size sizePreview = size;
    if (widget.widthPreview != null && widget.heightPreview != null) {
      sizePreview = Size(widget.widthPreview!, widget.heightPreview!);
    }

    var scale = sizePreview.aspectRatio * camera.aspectRatio;

    // // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    // Store values for result points transformation
    _scale = scale;
    _previewSize = sizePreview;
    _cameraSize = Size(
      camera.previewSize!.height,
      camera.previewSize!.width,
    );

    return ClipRRect(
      child: SizedBox(
        key: _cameraKey,
        width: widget.widthPreview,
        height: widget.heightPreview,
        child: Stack(
          children: [
            Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(
                  cameraController,
                ),
              ),
            ),
            if (controller.state.value.typeScan == TypeScan.takePicture)
              _buildButton(),
            widget.child ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void _onStateListener() {
    final state = controller.state.value;
    if (state.initialized != initialized) {
      postFrame(() {
        setState(() {
          _cameraKey = Key(controller.state.value.typeCamera.toString());
          initialized = controller.state.value.initialized;
        });
      });
    }
    if (state.result != null) {
     final result = Result(
        state.result!.text,
        state.result!.rawBytes,
        _fixResultPoints(state.result!.resultPoints),
        state.result!.barcodeFormat,
        state.result!.timestamp,
      );
      widget.onCapture?.call(result);
    }
  }

  List<ResultPoint?>? _fixResultPoints(List<ResultPoint?>? resultPoints) {
    if (resultPoints == null || resultPoints.isEmpty) {
      return resultPoints;
    }

    if (_cameraSize == Size.zero || _previewSize == Size.zero) {
      return resultPoints;
    }

    final cameraController = controller.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return resultPoints;
    }

    // Tamanho da câmera conforme reportado pelo hardware
    final originalPreviewSize = cameraController.value.previewSize!;
    final cameraWidth = originalPreviewSize.width;
    final cameraHeight = originalPreviewSize.height;

    // Detectar orientação da câmera e do preview
    final cameraIsLandscape = cameraWidth > cameraHeight;
    final previewIsLandscape = _previewSize.width > _previewSize.height;

    // Precisamos rotacionar se as orientações são diferentes
    final needsRotation = cameraIsLandscape != previewIsLandscape;

    // Dimensões finais da imagem após rotação (se necessário)
    double finalImageWidth, finalImageHeight;
    if (needsRotation) {
      // Após rotação 90°, largura e altura são invertidas
      finalImageWidth = cameraHeight;
      finalImageHeight = cameraWidth;
    } else {
      finalImageWidth = cameraWidth;
      finalImageHeight = cameraHeight;
    }

    // Aplicar a mesma escala uniforme que é aplicada ao CameraPreview
    final scaledImageWidth = finalImageWidth * _scale;
    final scaledImageHeight = finalImageHeight * _scale;

    // Calcular crop (parte que fica fora do preview)
    final cropX = (scaledImageWidth - _previewSize.width) / 2;
    final cropY = (scaledImageHeight - _previewSize.height) / 2;

    // Transformar todos os pontos
    final transformedPoints = <ResultPoint>[];
    for (final point in resultPoints) {
      if (point == null) continue;

      double transformedX, transformedY;

      if (needsRotation) {
        // Rotação 90° horário: (x, y) → (height - y, x)
        transformedX = cameraHeight - point.y;
        transformedY = point.x;
      } else {
        // Sem rotação, usar coordenadas originais
        transformedX = point.x;
        transformedY = point.y;
      }

      // Aplicar escala uniforme e remover crop
      final fixedX = (transformedX * _scale) - cropX;
      final fixedY = (transformedY * _scale) - cropY;

      transformedPoints.add(ResultPoint(fixedX, fixedY));
    }

    if (transformedPoints.isEmpty) {
      return resultPoints;
    }

    // Calcular bounding box
    double minX = transformedPoints.first.x;
    double maxX = transformedPoints.first.x;
    double minY = transformedPoints.first.y;
    double maxY = transformedPoints.first.y;

    for (final point in transformedPoints) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    // Retornar os 4 cantos do quadrilátero (bounding box)
    return [
      ResultPoint(minX, minY), // Top-left
      ResultPoint(maxX, minY), // Top-right
      ResultPoint(maxX, maxY), // Bottom-right
      ResultPoint(minX, maxY), // Bottom-left
    ];
  }
}

class _ButtonTakePicture extends StatelessWidget {
  static const buttonContainerHeight = 150.0;
  static const buttonSize = 80.0;
  static const progressSize = 40.0;
  final VoidCallback onTakePicture;
  final bool isLoading;
  const _ButtonTakePicture({
    Key? key,
    required this.onTakePicture,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: buttonContainerHeight,
        color: Colors.black,
        child: Center(
          child: InkWell(
            onTap: onTakePicture,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: progressSize,
                          height: progressSize,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// If return true the newResult is passed in 'onCapture'
typedef OnResultInterceptorCallback = bool Function(
  Result? oldREsult,
  Result newResult,
);
