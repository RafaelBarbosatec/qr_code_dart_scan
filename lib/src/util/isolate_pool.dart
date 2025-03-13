import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';

enum IsolateTaskType { planes, image }

class IsolatePool {
  final int size;
  final List<Isolate> _isolates = [];
  final List<SendPort> _sendPorts = [];
  final Queue<Completer> _taskQueue = Queue();
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
        if (_taskQueue.isNotEmpty) {
          final completer = _taskQueue.removeFirst();
          completer.complete(message);
        }
      });
    }
    _initialized = true;
  }

  Future<dynamic> runTask(dynamic message) {
    if (!_initialized) return Future.value();
    if (_sendPorts.isEmpty) return Future.value();
    final completer = Completer();
    _taskQueue.add(completer);

    // Find the next available isolate
    final sendPort = _sendPorts[(_taskQueue.length - 1) % size];
    sendPort.send(message);

    return completer.future;
  }

  void dispose() {
    _initialized = false;
    for (var isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _sendPorts.clear();
    _taskQueue.clear();
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
    switch (message['type']) {
      case IsolateTaskType.planes:
        return CameraDecode.decode(message);
      case IsolateTaskType.image:
        return FileDecode.decode(message);
    }

    return Future.value();
  }
}
