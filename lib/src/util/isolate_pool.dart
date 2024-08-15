import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:qr_code_dart_scan/src/decoder/image_decoder.dart';

class IsolatePool {
  final int size;
  final List<Isolate> _isolates = [];
  final List<SendPort> _sendPorts = [];
  final Queue<Completer> _taskQueue = Queue();
  final StreamController<dynamic> _resultStreamController =
      StreamController.broadcast();
  bool _initialized = false;

  IsolatePool(this.size);

  Future<void> start() async {
    if (_initialized) return;

    for (int i = 0; i < size; i++) {
      ReceivePort receivePort = ReceivePort();
      Isolate isolate = await Isolate.spawn(
        _isolateEntry,
        receivePort.sendPort,
      );
      _isolates.add(isolate);

      // Listen for results from the isolate
      receivePort.listen((message) {
        if (message is SendPort) {
          _sendPorts.add(message);
          return;
        }
        final completer = _taskQueue.removeFirst();
        completer.complete(message);
      });
    }
    _initialized = true;
  }

  Future<dynamic> runTask(dynamic message) {
    if (!_initialized) return Future.value();
    final completer = Completer();
    _taskQueue.add(completer);

    // Find the next available isolate
    final sendPort = _sendPorts[_taskQueue.length % size];
    sendPort.send(message);

    return completer.future;
  }

  void dispose() {
    for (var isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    _resultStreamController.close();
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      // Process the message and send back the result
      final result = await _processTask(message);
      mainSendPort.send(result);
    });
  }

  static dynamic _processTask(dynamic message) {
    return ImageDecoder.decodePlanes(message);
  }
}
