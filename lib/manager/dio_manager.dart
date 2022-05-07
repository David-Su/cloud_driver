import 'dart:convert';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Transformer<T> = BaseEntity<T> Function(Map<String, dynamic> json);
typedef Handler<T> = T? Function(BaseEntity<T> baseEntity);

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
    defaultDio.interceptors.add(MyInterceptor());
  }

  Future<T?> doPost<T>(
          {required String api,
          data,
          required Transformer<T> transformer,
          required BuildContext context,
          Handler? interceptor}) =>
      defaultDio.post(api, data: data).then((value) {
            BaseEntity<T> baseEntity =
                transformer.call(json.decode(value.toString()));

            if (interceptor != null) {
              return interceptor.call(baseEntity);
            }

            switch (baseEntity.code) {
              case NetworkConfig.codeOk:
                return baseEntity.result;
              case NetworkConfig.codeTokenTimeOut:
                break;
              case NetworkConfig.codeUnOrPwError:
                break;
            }
            return null;
          });
}

class MyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    SharedPreferences.getInstance()
        .then((value) => options.queryParameters
            .addAll({"token": value.getString(SpConfig.keyToken)}))
        .then((value) => super.onRequest(options, handler));
  }
}
