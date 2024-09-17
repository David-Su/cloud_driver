import 'dart:async';
import 'dart:ui';

import 'package:cloud_driver/manager/platform/mobile_platform_adapter.dart'
    if (dart.library.html) 'package:cloud_driver/manager/platform/web_platform_adapter.dart'
    as impl;

/// @Author SuK
/// @Des
/// @Date 2023/4/28
abstract class PlatformAdapter {
  factory PlatformAdapter() {
    return impl.PlatformAdapterImpl();
  }

  Size? webGetScreenSize();

  void webBlocRightClick();

  void webOpen({required String url});

  FutureOr<void> uploadFile(
      {required bool isDir,
      required FutureOr<String> Function({String dir}) getFileParentPath,
      required FutureOr<void> Function() onTaskDown});
}
