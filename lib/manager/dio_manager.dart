import 'dart:math';

import 'package:cloud_driver/config/config.dart';
import 'package:dio/dio.dart';

class DioManager {
  static final DioManager _instance = DioManager._internal();

  factory DioManager() => _instance;

  late final Dio defaultDio;

  DioManager._internal() {
    defaultDio = Dio(BaseOptions(
        baseUrl: NetworkConfig.urlBase,
        connectTimeout: NetworkConfig.timeoutReceive));
    defaultDio.interceptors
        .add(LogInterceptor(responseBody: true, requestBody: true));
  }
}
