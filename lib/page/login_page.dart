import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/model/entity/login_entity.dart';
import 'package:cloud_driver/model/global.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/entity/base_entity.dart';
import '../util/util.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loginArgs = ModalRoute.of(context)?.settings.arguments as LoginArgs?;

    final unameController = TextEditingController();

    final pswController = TextEditingController();

    final refreshToken = loginArgs?.refreshToken == true;

    final username = Global.username;
    print("全局用户名->${username}");
    if (refreshToken && username != null && username.isNotEmpty == true) {
      unameController.text = username;
    }

    final title;

    if (refreshToken) {
      title = "重新登录";
    } else {
      title = "登录";
    }

    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Text(title),
            ),
            body: Center(
              child: Column(
                children: [
                  TextField(
                      readOnly: refreshToken,
                      controller: unameController,
                      decoration: const InputDecoration(
                          labelText: "用户名", prefixIcon: Icon(Icons.person))),
                  TextField(
                      controller: pswController,
                      decoration: const InputDecoration(
                          labelText: "密码", prefixIcon: Icon(Icons.person))),
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          var futureSp =
                              Future(() => SharedPreferences.getInstance());

                          var futureLogin = DioManager().doPost(
                              api: NetworkConfig.apiLogin,
                              data: {
                                "username": unameController.text,
                                "password": pswController.text
                              },
                              transformer: (json) => LoginEntity.fromJson(json),
                              context: context,
                              interceptor: (BaseEntity<LoginResult> baseEntity,
                                  DefaultHandler<LoginResult> defaultHandler) {
                                switch (baseEntity.code) {
                                  case NetworkConfig.codeOk:
                                    return baseEntity;
                                  default:
                                    ToastUtil.showDefaultToast(
                                        context, baseEntity.message);
                                    break;
                                }
                              });

                          await Future.wait([futureSp, futureLogin])
                              .then((value) {
                            LoginResult? result =
                                (value[1] as LoginEntity?)?.result;

                            if (result == null) return;

                            SharedPreferences sp =
                                value[0] as SharedPreferences;

                            sp.setString(SpConfig.keyToken, result.token);

                            print(
                                "本地token->${sp.getString(SpConfig.keyToken)}");
                          });

                          final values =
                              await Future.wait([futureSp, futureLogin]);

                          SharedPreferences sp = values[0] as SharedPreferences;

                          LoginResult? result =
                              (values[1] as LoginEntity?)?.result;

                          if (result == null) return;

                          sp.setString(SpConfig.keyToken, result.token);

                          Global.username = unameController.text;

                          print("保存username->${Global.username}");

                          if (refreshToken) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).popAndPushNamed("/file");
                          }
                        },
                        icon: const Icon(Icons.login),
                        label: const Text("登录"),
                      ))
                ],
              ),
            )),
        onWillPop: () async => false);
  }
}

class LoginArgs {
  final bool refreshToken;

  LoginArgs(this.refreshToken);
}
