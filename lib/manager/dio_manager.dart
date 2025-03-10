import 'dart:async';
import 'dart:convert';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/main.dart';
import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:cloud_driver/page/login/login_page.dart';
import 'package:cloud_driver/util/util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef DefaultHandle<T> = BaseEntity<T>? Function(
    BuildContext context, BaseEntity<T> baseEntity);
typedef Handler<T> = BaseEntity<T>? Function(
    BaseEntity<T> baseEntity, DefaultHandle<T> defaultHandler);

class DioManager {
  static final DioManager _instance = DioManager._internal();

  factory DioManager() => _instance;

  late final Dio defaultDio;

  final List<Completer<void>> _jobs = [];

  DioManager._internal() {
    defaultDio = Dio(BaseOptions(
        baseUrl: NetworkConfig.urlBase,
        connectTimeout:
            const Duration(milliseconds: NetworkConfig.timeoutConnect)));
    defaultDio.interceptors
      ..add(LogInterceptor(responseBody: true, requestBody: true))
      ..add(MyInterceptor());
  }

  Completer<BuildContext>? _dialogCompleter = null;

  Future<BaseEntity<T>?> doPost<T>(
      {required String api,
      data,
      required BaseEntity<T> Function(Map<String, dynamic> json) transformer,
      required BuildContext context,
      ProgressCallback? onSendProgress,
      Handler<T>? interceptor,
      bool isShowDialog = true}) async {
    final job = Completer<void>();

    _jobs.add(job);

    if (isShowDialog && _dialogCompleter == null) {
      final dialogCompleter = Completer<BuildContext>();
      _dialogCompleter = dialogCompleter;
      showDialog(
          context: MyApp.navigatorKey.currentContext!,
          builder: (BuildContext dialogContext) {
            //调用这次showDialog之前如果有弹窗的话,builder会走两次,未知原因
            if (!dialogCompleter.isCompleted) {
              dialogCompleter.complete(dialogContext);
            }
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
          });
    }

    Response? resp;

    try {
      resp = await defaultDio.post(api,
          data: data, onSendProgress: onSendProgress);
    } catch (err) {
      if (err is DioException) {
        final msg = err.message;
        if (msg != null && msg.isNotEmpty) {
          Util.showDefaultToast(msg);
        }

        switch (err.type) {
          case DioExceptionType.connectionTimeout:
            break;
          case DioExceptionType.sendTimeout:
            break;
          case DioExceptionType.receiveTimeout:
            break;
          default:
            break;
        }
      } else {
        Util.showDefaultToast("网络访问异常");
        debugPrint(err.toString());
      }
    }

    //loading dialog 相关
    job.complete();
    _jobs.remove(job);
    if (_jobs.isEmpty) {
      final completer = _dialogCompleter;
      if (completer != null) {
        final context = await completer.future;
        try {
          Navigator.of(context).pop();
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      _dialogCompleter = null;
    }

    if (resp == null) return null;

    final BaseEntity<T>? result;
    final baseEntity = transformer.call(resp.data);
    if (interceptor != null) {
      result = interceptor.call(baseEntity, defaultHandle);
    } else {
      result = defaultHandle(context, baseEntity);
    }

    return result;
  }

  BaseEntity<T>? defaultHandle<T>(
      BuildContext context, BaseEntity<T> baseEntity) {
    if (baseEntity.code != NetworkConfig.codeOk) {
      Util.showDefaultToast(baseEntity.message);
    }

    switch (baseEntity.code) {
      case NetworkConfig.codeOk:
        return baseEntity;
      case NetworkConfig.codeTokenTimeOut:
        Navigator.of(context).pushNamed("/login",
            arguments: LoginArgs(LoginReason.refreshToken));
        break;
      case NetworkConfig.codeUnOrPwError:
        break;
    }
    return null;
  }

  void waitJobsFinish() async {
    final it = _jobs.iterator;
    while (it.moveNext()) {
      await it.current.future;
    }
  }
}

class MyInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(SpConfig.keyToken);
    options.queryParameters.addAll({"token": token});
    super.onRequest(options, handler);
  }
}
