import 'package:flutter/material.dart';

import 'live_decode.dart';
import 'picture_decode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        ...HomePage.route,
        ...LiveDecodePage.route,
        ...PictureDecode.route,
      },
    );
  }
}

class HomePage extends StatelessWidget {
  static const routeName = '/';
  static get route => {routeName: (BuildContext context) => const HomePage()};

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRCodeDartScan'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => LiveDecodePage.open(context),
              child: const Text('Live decode'),
            ),
            ElevatedButton(
              onPressed: () => PictureDecode.open(context),
              child: const Text('Picture decode'),
            )
          ],
        ),
      ),
    );
  }
}
