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
  static get route =>
      {routeName: (BuildContext context) => const LiveDecodePage()};
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRCodeDartScanView(
        controller: _controller,
        scanInvertedQRCode: true,
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
                Text('Text: ${currentResult?.text ?? 'Not found'}'),
                Text('Format: ${currentResult?.barcodeFormat ?? 'Not found'}'),
                ElevatedButton(
                    onPressed: () {
                      _controller.changeCamera(TypeCamera.front);
                    },
                    child: const Text('Change cam')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
