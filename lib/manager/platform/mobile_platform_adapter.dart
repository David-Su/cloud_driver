import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/util/util.dart';
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

  static Future<List<String>> _compute() async {
    final files = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: false, withReadStream: true)
        .then((value) => value?.files);
    return files?.map((e) => e.path!).toList() ?? [];
  }

  @override
  FutureOr<void> uploadFile(
      {required bool isDir,
      required FutureOr<String> Function({String dir}) getFileParentPath,
      required FutureOr<void> Function() onTaskDown}) async {
    final files = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: false, withReadStream: true)
        .then((value) => value?.files);

    if (files == null || files.isEmpty) return;

    final filePaths = files.map((e) => e.path!).toList();

    if (filePaths.isEmpty) {
      Util.showDefaultToast("没有有效的文件");
    }

    const uuid = Uuid();

    await Future.wait(filePaths.map((path) async {
      final completer = Completer();
      final portName = uuid.v4();
      final receivePort = ReceivePort();
      IsolateNameServer.registerPortWithName(
        receivePort.sendPort,
        portName,
      );
      receivePort.listen((message) {
        debugPrint("receivePort listen:${message}");
        IsolateNameServer.removePortNameMapping(portName);
        receivePort.close();
        completer.complete();
      });

      final fileParentPath = await getFileParentPath();

      final inputData = {
        "fileParentPath": fileParentPath,
        "localFilePath": path,
        "portName": portName,
      };

      Workmanager().registerOneOffTask(uuid.v4(), work_manager.uploadTaskKey,
          constraints: Constraints(
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresDeviceIdle: false,
              networkType: NetworkType.not_required),
          inputData: inputData);
      await completer.future;
      await onTaskDown();
    }));
  }
}
