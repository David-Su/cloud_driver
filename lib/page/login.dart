import 'dart:convert';
import 'dart:io';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/model/entity/login_entity.dart';
import 'package:cloud_driver/model/handler/base_entity_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _unameController = TextEditingController();

  final TextEditingController _pswController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("登录"),
        ),
        body: Center(
          child: Column(
            children: [
              TextField(
                  controller: _unameController,
                  decoration: const InputDecoration(
                      labelText: "用户名", prefixIcon: Icon(Icons.person))),
              TextField(
                  controller: _pswController,
                  decoration: const InputDecoration(
                      labelText: "密码", prefixIcon: Icon(Icons.person))),
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      var FutureSp =
                          Future(() => SharedPreferences.getInstance());

                      var FutureLoging = DioManager()
                          .defaultDio
                          .post(NetworkConfig.apiLogin, data: {
                        "username": _unameController.text,
                        "password": _pswController.text
                      }).then((value) {
                        var login =
                            LoginEntity.fromJson(json.decode(value.toString()));
                        return BaseEntityHandler(login, context).getResult();
                      });

                      Future.wait([FutureSp, FutureLoging]).then((value) {
                        LoginResult? result = value[1] as LoginResult?;

                        if (result == null) return;

                        SharedPreferences sp = value[0] as SharedPreferences;

                        sp.setString(SpConfig.keyToken, result.token);
                      });
                    },
                    icon: const Icon(Icons.login),
                    label: const Text("登录"),
                  ))
            ],
          ),
        ));
  }
}
