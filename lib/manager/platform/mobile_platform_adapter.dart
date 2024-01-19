import 'dart:async';
import 'dart:ui';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

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
        .pickFiles(allowMultiple: true, withReadStream: true)
        .then((value) => value?.files);

    if (files == null) return;

    await Future.wait(files.map((file) async {
      final stream = file.readStream;
      if (stream == null) {
        return;
      }
      final formData = FormData.fromMap(
          {"file": MultipartFile(stream, file.size, filename: file.name)});

      final filePath = await getFileParentPath();

      await DioManager().defaultDio.post(
          "${NetworkConfig.urlBase}${NetworkConfig.apiUploadFile}?path=$filePath",
          data: formData);
    }));
  }
}
