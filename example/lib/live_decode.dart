import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

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
/// on 28/06/22
class LiveDecodePage extends StatefulWidget {
  static const routeName = '/live';
  static get route => {routeName: (BuildContext context) => const LiveDecodePage()};
  static open(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const LiveDecodePage({Key? key}) : super(key: key);

  @override
  LiveDecodePageState createState() => LiveDecodePageState();
}

class LiveDecodePageState extends State<LiveDecodePage> {
  Result? currentResult;
  final QRCodeDartScanController _controller = QRCodeDartScanController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRCodeDartScanView(
        controller: _controller,
        resolutionPreset: QRCodeDartScanResolutionPreset.medium,
        onCapture: (Result result) {
          setState(() {
            currentResult = result;
          });
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('isLive: ${_controller.isLiveScan}'),
                Text('Text: ${currentResult?.text ?? 'Not found'}'),
                Text('Format: ${currentResult?.barcodeFormat ?? 'Not found'}'),
                ElevatedButton(
                  onPressed: () async {
                    _controller.changeCamera(
                      _controller.state.value.typeCamera == TypeCamera.front
                          ? TypeCamera.back
                          : TypeCamera.front,
                    );
                  },
                  child: const Text('Change cam'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_controller.isLiveScan) {
                      await _controller.stopScan();
                      currentResult = null;
                    } else {
                      await _controller.startScan();
                    }
                    setState(() {});
                  },
                  child: Text(
                    _controller.isLiveScan ? 'Stop scan' : 'Start scan',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
