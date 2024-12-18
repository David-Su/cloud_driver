import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/util/util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path/path.dart' as path;

import '../config/config.dart';
import 'dio_manager.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

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
    debugPrint("Native called background task: $task");

    switch (task) {
      case uploadTaskKey:
        final String fileParentPath = inputData!['fileParentPath'];
        final String localFilePath = inputData!['localFilePath'];
        final String portName = inputData!['portName'];

        final file = File(localFilePath);
        final fileLength = await file.length();
        final fileName = path.basename(file.path);
        final stream = file.openRead(0, fileLength);

        debugPrint("$task upload start");

        final formData = FormData.fromMap(
            {"file": MultipartFile(stream, fileLength, filename: fileName)});

        await DioManager().defaultDio.post(
            "${NetworkConfig.urlBase}${NetworkConfig.apiUploadFile}?path=$fileParentPath",
            data: formData);

        debugPrint("$task upload end");

        IsolateNameServer.lookupPortByName(portName)?.send(null);
        break;
    }
//simpleTask will be emitted here.
    return true;
  });
}
