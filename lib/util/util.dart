import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil{

  ToastUtil._internal();

  static showDefaultToast(BuildContext context,String content){
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
          content,
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ),
      gravity: ToastGravity.CENTER,
      toastDuration: const Duration(seconds: 2),
    );
  }
}