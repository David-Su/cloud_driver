import 'dart:async';
import 'dart:html' as html;
import 'dart:ui';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// @Author SuK
/// @Des
/// @Date 2023/4/28
class PlatformAdapterImpl implements PlatformAdapter {
  @override
  Size webGetScreenSize() => Size(html.window.screen?.width?.toDouble() ?? 0,
      html.window.screen?.height?.toDouble() ?? 0);

  @override
  void webBlocRightClick() =>
      html.window.document.onContextMenu.listen((evt) => evt.preventDefault());

  @override
  void webOpen({required String url}) {
    html.window.open(url, "_self");
  }

  FutureOr<void> uploadFile(
      {required bool isDir,
      required FutureOr<String> Function({String dir}) getFileParentPath,
      required FutureOr<void> Function() onTaskDown}) async {
    // await _uploadOldWay(emit);

    final currentUploadCompleter = Completer();

    final token =
        (await SharedPreferences.getInstance()).getString(SpConfig.keyToken);

    final element = html.InputElement(type: 'file');
    // final element = html.FileUploadInputElement();
    element.multiple = true;
    element.draggable = false;
    element.directory = isDir;
    element.click();

    element.onChange.listen((event) async {
      final files = element.files;

      if (files == null || files.isEmpty == true) {
        return;
      }

      final String filePath;

      if (isDir) {
        // final dir = element.dirName;
        final dir = files.first.relativePath?.split("/").first;
        if (dir != null && dir.isNotEmpty) {
          filePath = await getFileParentPath(dir: dir);
        } else {
          return;
        }
      } else {
        filePath = await getFileParentPath();
      }

      int loadEndFlag = 0;

      for (final file in files) {
        final formData = html.FormData();
        final request = html.HttpRequest();

        request.onLoadEnd.listen((event) async {
          await onTaskDown();
          if (++loadEndFlag == files.length) currentUploadCompleter.complete();
        });

        request.open("POST",
            "${NetworkConfig.urlBase}${NetworkConfig.apiUploadFile}?token=$token&path=$filePath");

        formData.appendBlob("file", file, file.name);
        request.send(formData);
      }
    });

    await currentUploadCompleter.future;
  }
}
