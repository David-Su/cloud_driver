import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_driver/manager/work_manager.dart' as work_manager;
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

/// @Author SuK
/// @Des
/// @Date 2023/4/28
class PlatformAdapterImpl implements PlatformAdapter {
  @override
  Size? webGetScreenSize() => null;

  @override
  void webBlocRightClick() {}

  @override
  void webOpen({required String url}) {}

  @override
  FutureOr<void> uploadFile(
      {required bool isDir,
      required FutureOr<String> Function({String dir})
          getFileParentPath}) async {

    final files = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: false, withReadStream: true)
        .then((value) => value?.files);

    if (files == null) return;

    const uuid = Uuid();

    await Future.wait(files.map((file) async {
      final completer = Completer();
      final portName = 'upload_finish_port_${files.indexOf(file)}';
      final receivePort = ReceivePort();
      IsolateNameServer.registerPortWithName(
        receivePort.sendPort,
        portName,
      );
      receivePort.listen((message) {
        developer.log('receivePort listen', name: 'PlatformAdapterImpl');
        debugPrint("receivePort listen");
        IsolateNameServer.removePortNameMapping(portName);
        receivePort.close();
        completer.complete();
      });

      final fileParentPath = await getFileParentPath();

      final inputData = {
        "fileParentPath": fileParentPath,
        "localFilePath": file.path,
        "portName": portName,
      };

      Workmanager().registerOneOffTask(uuid.v1(), work_manager.uploadTaskKey,
          constraints: Constraints(
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresDeviceIdle: false,
              networkType: NetworkType.not_required),
          inputData: inputData);

      await await completer.future;
    }));
  }
}
