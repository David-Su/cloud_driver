import 'dart:async';
import 'dart:ui';

import 'package:cloud_driver/manager/platform/platform_adapter.dart';

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
  FutureOr<void> uploadFile({required bool isDir, required FutureOr<String> Function({String dir}) getFileParentPath}) {}
}
