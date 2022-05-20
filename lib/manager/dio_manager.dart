import 'dart:async';
import 'dart:convert';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Transformer<T> = BaseEntity<T> Function(Map<String, dynamic> json);
typedef DefaultHandler<T> = BaseEntity<T>? Function(BaseEntity<T> baseEntity);
typedef Handler<T> = BaseEntity<T>? Function(
    BaseEntity<T> baseEntity, DefaultHandler<T> defaultHandler);

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

  Future<BaseEntity<T>?> doPost<T>(
      {required String api,
      data,
      required Transformer<T> transformer,
      required BuildContext context,
      ProgressCallback? onSendProgress,
      Handler<T>? interceptor}) async {
    final dialogCompleter = Completer<BuildContext>();

    Future(() => showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          dialogCompleter.complete(dialogContext);
          return Center(
            child: Container(
                child: const Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(),
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8))),
          );
        }));

    final value =
        await defaultDio.post(api, data: data, onSendProgress: onSendProgress);

    Navigator.of((await dialogCompleter.future)).pop();

    BaseEntity<T> baseEntity = transformer.call(json.decode(value.toString()));

    final defaultHandler = (BaseEntity<T> baseEntity) {
      if (baseEntity.code != NetworkConfig.codeOk) {
        final toast = FToast()..init(context);
        toast.showToast(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              color: Theme.of(context).hoverColor,
            ),
            child: Text(
              baseEntity.message,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          gravity: ToastGravity.TOP,
          toastDuration: const Duration(seconds: 2),
        );
      }

      switch (baseEntity.code) {
        case NetworkConfig.codeOk:
          return baseEntity;
        case NetworkConfig.codeTokenTimeOut:
          Navigator.of(context).popAndPushNamed("/login");
          break;
        case NetworkConfig.codeUnOrPwError:
          break;
      }
      return null;
    };

    if (interceptor != null) {
      return interceptor.call(baseEntity, defaultHandler);
    }

    return defaultHandler.call(baseEntity);
  }
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
