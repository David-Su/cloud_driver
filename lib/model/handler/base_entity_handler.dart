import 'dart:async';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';

typedef Interceptor<T> = T? Function(BaseEntity<T> baseEntity);

class BaseEntityHandler<T> {
  BaseEntity<T> baseEntity;
  BuildContext context;
  Interceptor<T>? interceptor;

  BaseEntityHandler(this.baseEntity, this.context, {this.interceptor});

  Future<T?> getResult() => Future(() {
        if (interceptor != null) {
          return interceptor?.call(baseEntity);
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
