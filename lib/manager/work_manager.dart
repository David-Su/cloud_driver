import 'dart:isolate';

import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:workmanager/workmanager.dart';

const uploadTaskKey = "uploadTaskKey";

final _platformAdapter = PlatformAdapter();

void init() {
  Workmanager().initialize(
      _callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task");

    switch (task) {
      case uploadTaskKey:
        final bool isDir = inputData!['isDir'];
        final String fileParentPath = inputData!['fileParentPath'];
        final SendPort sendPort = inputData!['sendPort'];
        await _platformAdapter.uploadFile(
            isDir: isDir,
            getFileParentPath: ({String? dir}) async {
              return fileParentPath;
            });
        sendPort.send(null);
        break;
    }
//simpleTask will be emitted here.
    return true;
  });
}
