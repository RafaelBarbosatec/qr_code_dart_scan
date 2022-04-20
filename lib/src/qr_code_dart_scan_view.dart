import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/src/extensions.dart';
import 'package:qr_code_dart_scan/src/qr_code_dart_scan_controller.dart';
import 'package:qr_code_dart_scan/src/util.dart';
import 'package:zxing_lib/zxing.dart';

import 'qr_code_dart_scan_decoder.dart';

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

class QRCodeDartScanView extends StatefulWidget {
  final TypeCamera typeCamera;
  final ValueChanged<Result>? onCapture;
  final bool scanInvertedQRCode;

  /// Use to limit a specific format
  /// If null use all accepted formats
  final List<BarcodeFormat>? formats;
  final QRCodeDartScanController? controller;
  final QrCodeDartScanResolutionPreset resolutionPreset;
  const QRCodeDartScanView({
    Key? key,
    this.typeCamera = TypeCamera.back,
    this.onCapture,
    this.scanInvertedQRCode = false,
    this.resolutionPreset = QrCodeDartScanResolutionPreset.high,
    this.controller,
    this.formats,
  }) : super(key: key);

  @override
  _QRCodeDartScanViewState createState() => _QRCodeDartScanViewState();
}

class _QRCodeDartScanViewState extends State<QRCodeDartScanView> {
  late CameraController controller;
  late QRCodeDartScanController qrCodeDartScanController;
  bool initialized = false;
  bool processingImg = false;

  @override
  void initState() {
    _verifyFormats();
    Future.delayed(Duration.zero, _initController);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: !initialized
          ? Container(
              width: double.maxFinite,
              height: double.maxFinite,
            )
          : Container(
              width: double.maxFinite,
              height: double.maxFinite,
              child: CameraPreview(controller),
            ),
    );
  }

  void _initController() async {
    final cameras = await availableCameras();
    var camera = cameras.first;
    if (widget.typeCamera == TypeCamera.front && cameras.length > 1) {
      camera = cameras[1];
    }
    controller = CameraController(
      camera,
      widget.resolutionPreset.toResolutionPreset(),
    );
    qrCodeDartScanController = widget.controller ?? QRCodeDartScanController();
    await controller.initialize();
    qrCodeDartScanController.configure(controller);
    controller.startImageStream(_imageStream);
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          initialized = true;
        });
      }
    });
  }

  void _imageStream(CameraImage image) async {
    if (!qrCodeDartScanController.scanEnable) return;
    if (!processingImg) {
      processingImg = true;
      Future.microtask(() => _processImage(image));
    }
  }

  void _processImage(CameraImage image) async {
    final event = DecodeEvent(
      cameraImage: image,
      formats: widget.formats,
    );
    Result? decoded = await compute(
      decode,
      event.toMap(),
    );

    if (widget.scanInvertedQRCode && decoded == null) {
      decoded = await compute(
        decode,
        event.copyWith(invert: true).toMap(),
      );
    }

    if (decoded != null && mounted) {
      widget.onCapture?.call(decoded);
    }
    processingImg = false;
  }

  void _verifyFormats() {
    if (widget.formats?.isNotEmpty == true) {
      widget.formats!.forEach((element) {
        if (!acceptedFormats.contains(element)) {
          throw Exception('$element format not supported in the moment');
        }
      });
    }
  }
}
