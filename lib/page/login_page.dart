import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/model/entity/login_entity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _unameController = TextEditingController();

  final TextEditingController _pswController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
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
                          var futureSp =
                          Future(() => SharedPreferences.getInstance());

                          var futureLogin = DioManager().doPost(
                              api: NetworkConfig.apiLogin,
                              data: {
                                "username": _unameController.text,
                                "password": _pswController.text
                              },
                              transformer: (json) => LoginEntity.fromJson(json),
                              context: context);

                          Future.wait([futureSp, futureLogin]).then((value) {
                            LoginResult? result = value[1] as LoginResult?;

                            if (result == null) return;

                            SharedPreferences sp =
                            value[0] as SharedPreferences;

                            sp.setString(SpConfig.keyToken, result.token);

                            print(
                                "本地token->${sp.getString(SpConfig.keyToken)}");
                          }).then((value) =>
                              Navigator.of(context).popAndPushNamed("/file"));
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
