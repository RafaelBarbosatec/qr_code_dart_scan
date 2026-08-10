import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:qr_code_dart_scan/src/util/qr_code_dart_scan_config.dart';

import 'fake_camera_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCameraPlatform platform;

  QRCodeDartScanConfig buildConfig({ValueChanged<String>? onCameraError}) =>
      QRCodeDartScanConfig(
        formats: BarcodeFormat.values,
        typeCamera: TypeCamera.back,
        typeScan: TypeScan.live,
        onCameraError: onCameraError,
      );

  setUp(() {
    platform = FakeCameraPlatform();
    CameraPlatform.instance = platform;
  });

  group('QRCodeDartScanController lifecycle', () {
    test('dispose during an in-flight config never starts the image stream',
        () async {
      final controller = QRCodeDartScanController();
      final gate = Completer<void>();
      platform.initializeGate = gate;

      final configFuture = controller.config(buildConfig());
      // Let config reach `initializeCamera` and block there.
      await Future<void>.delayed(Duration.zero);

      final disposeFuture = controller.dispose();
      gate.complete();

      await configFuture;
      await disposeFuture;

      expect(platform.startedStreams, isEmpty);
      expect(controller.cameraController, isNull);
      expect(controller.state.value.initialized, isFalse);
      // The camera created by the aborted init must not stay open.
      expect(platform.openCameras, isEmpty);
    });

    test('rapid config/dispose/config leaves exactly one camera open',
        () async {
      final controller = QRCodeDartScanController();

      // No awaits in between: this is the pause/resume flicker.
      unawaited(controller.config(buildConfig()));
      unawaited(controller.dispose());
      await controller.config(buildConfig());

      expect(platform.openCameras, hasLength(1));
      expect(controller.cameraController, isNotNull);
      expect(controller.state.value.initialized, isTrue);
      expect(platform.startedStreams, hasLength(1));
    });

    test('cameraController is null after dispose', () async {
      final controller = QRCodeDartScanController();
      await controller.config(buildConfig());
      expect(controller.cameraController, isNotNull);

      await controller.dispose();

      expect(controller.cameraController, isNull);
      expect(controller.isInitialized, isFalse);
      expect(platform.openCameras, isEmpty);
    });

    test('controller can be reused after dispose', () async {
      final controller = QRCodeDartScanController();
      await controller.config(buildConfig());
      await controller.dispose();
      await controller.config(buildConfig());

      expect(controller.cameraController, isNotNull);
      expect(controller.state.value.initialized, isTrue);
      expect(platform.openCameras, hasLength(1));
    });

    test('a paused scan stays paused when the camera is restarted', () async {
      final controller = QRCodeDartScanController();
      await controller.config(buildConfig());
      expect(platform.startedStreams, hasLength(1));

      await controller.stopScan();
      expect(controller.isScanPaused, isTrue);

      // App minimized and reopened (this is what the view does on resume).
      await controller.dispose();
      await controller.config(buildConfig(), keepScanPaused: true);

      // Preview is back...
      expect(controller.isInitialized, isTrue);
      expect(controller.state.value.initialized, isTrue);
      // ...but the decoding is not.
      expect(platform.startedStreams, hasLength(1));
      expect(controller.isLiveScan, isFalse);
      expect(controller.isScanPaused, isTrue);

      // And it can be resumed explicitly.
      await controller.startScan();
      expect(platform.startedStreams, hasLength(2));
      expect(controller.isLiveScan, isTrue);
      expect(controller.isScanPaused, isFalse);

      await controller.dispose();
    });

    test('a fresh config clears a paused scan', () async {
      final controller = QRCodeDartScanController();
      await controller.config(buildConfig());
      await controller.stopScan();
      await controller.dispose();

      // A remount of the view (as opposed to an app lifecycle resume) starts a
      // new scanning session.
      await controller.config(buildConfig());

      expect(controller.isScanPaused, isFalse);
      expect(platform.startedStreams, hasLength(2));

      await controller.dispose();
    });

    test('changeTypeScan back to live clears the paused state', () async {
      final controller = QRCodeDartScanController();
      await controller.config(buildConfig());
      await controller.stopScan();

      await controller.changeTypeScan(TypeScan.takePicture);
      await controller.changeTypeScan(TypeScan.live);

      expect(controller.isScanPaused, isFalse);
      expect(platform.startedStreams, hasLength(2));

      await controller.dispose();
    });

    test('a failing startImageStream is reported to the zone', () async {
      platform.failImageStream = true;
      final zoneErrors = <Object>[];
      final reportedCodes = <String>[];

      await runZonedGuarded(
        () async {
          final controller = QRCodeDartScanController();
          await controller.config(
            buildConfig(onCameraError: reportedCodes.add),
          );
          await controller.dispose();
        },
        (Object error, StackTrace stack) => zoneErrors.add(error),
      );

      // The package deliberately does not swallow this one: it must keep
      // reaching crash reporting.
      expect(zoneErrors, hasLength(1));
      expect(zoneErrors.single, isA<CameraException>());
      expect(
        (zoneErrors.single as CameraException).code,
        'Disposed CameraController',
      );
      // ...and it is still delivered through the regular callback.
      expect(reportedCodes, ['Disposed CameraController']);
    });

    test('changeCamera does not leak the previous camera', () async {
      final controller = QRCodeDartScanController();
      await controller.config(buildConfig());
      await controller.changeCamera(TypeCamera.front);

      expect(platform.openCameras, hasLength(1));
      expect(platform.disposedCameras, hasLength(1));

      await controller.dispose();
    });
  });

  group('QRCodeDartScanView lifecycle', () {
    testWidgets('pause/resume flicker does not touch a disposed controller',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QRCodeDartScanView(
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<QRCodeDartScanViewState>(
        find.byType(QRCodeDartScanView),
      );

      for (int i = 0; i < 5; i++) {
        state.didChangeAppLifecycleState(AppLifecycleState.inactive);
        state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      }
      await tester.pumpAndSettle();
      // Let the camera setup/teardown futures drain.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(platform.openCameras, hasLength(1));
    });

    testWidgets('minimize/reopen with a paused scan restores only the preview',
        (WidgetTester tester) async {
      final controller = QRCodeDartScanController();
      await tester.pumpWidget(
        MaterialApp(
          home: QRCodeDartScanView(
            controller: controller,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.startedStreams, hasLength(1));

      // `runAsync` is required: `CameraController.stopImageStream()` does not
      // complete under the fake async clock used by `testWidgets`.
      await tester.runAsync(controller.stopScan);

      final state = tester.state<QRCodeDartScanViewState>(
        find.byType(QRCodeDartScanView),
      );
      state.didChangeAppLifecycleState(AppLifecycleState.inactive);
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Camera is back up...
      expect(platform.openCameras, hasLength(1));
      expect(state.initialized, isTrue);
      // ...without resuming the scan.
      expect(platform.startedStreams, hasLength(1));
      expect(controller.isScanPaused, isTrue);
    });

    testWidgets('unmounting while initializing disposes the camera',
        (WidgetTester tester) async {
      final gate = Completer<void>();
      platform.initializeGate = gate;

      await tester.pumpWidget(
        const MaterialApp(
          home: QRCodeDartScanView(
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      gate.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(platform.startedStreams, isEmpty);
      expect(platform.openCameras, isEmpty);
    });
  });
}
