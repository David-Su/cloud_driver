import 'package:cloud_driver/main.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil {
  ToastUtil._internal();

  static showDefaultToast(String content) {
    final context = MyApp.navigatorKey.currentContext!;
    final _fToast = FToast()..init(context);
    _fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Theme.of(context).primaryColor,
        ),
        child: Text(
          content,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }
}
