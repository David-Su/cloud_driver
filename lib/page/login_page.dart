import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/manager/event_bus_manager.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/model/entity/login_entity.dart';
import 'package:cloud_driver/model/event/event.dart';
import 'package:cloud_driver/model/global.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/entity/base_entity.dart';
import '../util/util.dart';

class LoginPage extends StatelessWidget {
  final _platformAdapter = PlatformAdapter();

  @override
  Widget build(BuildContext context) {
    final loginArgs = ModalRoute.of(context)?.settings.arguments as LoginArgs?;

    final unameController = TextEditingController();

    final pswController = TextEditingController();

    final refreshToken = loginArgs?.refreshToken == true;

    //登录框的宽度
    final webScreenWidth = _platformAdapter.webGetScreenSize()?.width ?? 0;
    final loginFrameWidth = webScreenWidth / 5;
    final bgWidth = webScreenWidth / 2;

    final username = Global.username;
    print("全局用户名->${username}");
    if (refreshToken && username != null && username.isNotEmpty == true) {
      unameController.text = username;
    }

    final title;

    if (refreshToken) {
      title = "重新登录";
    } else {
      title = "登录云盘";
    }

    return WillPopScope(
        child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: Stack(
              children: [
                Center(
                  child: Image.network(
                    "web/icons/ic_login.svg",
                    width: bgWidth,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                // Align(alignment: Alignment.topCenter, child: Image.network("web/icons/ic_login.svg")),
                Center(
                  child: SingleChildScrollView(
                    child: Card(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        width: loginFrameWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            TextField(
                                controller: unameController,
                                decoration: const InputDecoration(
                                  labelText: "用户名",
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                )),
                            const SizedBox(
                              height: 20,
                            ),
                            TextField(
                                controller: pswController,
                                decoration: const InputDecoration(
                                  labelText: "密码",
                                  prefixIcon: Icon(Icons.password),
                                  border: OutlineInputBorder(),
                                )),
                            const SizedBox(
                              height: 30,
                            ),
                            Container(
                                padding: const EdgeInsets.all(10),
                                constraints: const BoxConstraints.tightFor(width: double.infinity),
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    var futureSp = Future(() => SharedPreferences.getInstance());

                                    var futureLogin = DioManager().doPost(
                                        api: NetworkConfig.apiLogin,
                                        data: {"username": unameController.text, "password": pswController.text},
                                        transformer: (json) => LoginEntity.fromJson(json),
                                        context: context,
                                        interceptor: (BaseEntity<LoginResult> baseEntity, DefaultHandle<LoginResult> defaultHandler) {
                                          switch (baseEntity.code) {
                                            case NetworkConfig.codeOk:
                                              return baseEntity;
                                            default:
                                              ToastUtil.showDefaultToast(baseEntity.message);
                                              break;
                                          }
                                        });

                                    await Future.wait([futureSp, futureLogin]).then((value) {
                                      LoginResult? result = (value[1] as LoginEntity?)?.result;

                                      if (result == null) return;

                                      SharedPreferences sp = value[0] as SharedPreferences;

                                      sp.setString(SpConfig.keyToken, result.token);

                                      print("本地token->${sp.getString(SpConfig.keyToken)}");
                                    });

                                    final values = await Future.wait([futureSp, futureLogin]);

                                    SharedPreferences sp = values[0] as SharedPreferences;

                                    LoginResult? result = (values[1] as LoginEntity?)?.result;

                                    if (result == null) return;

                                    sp.setString(SpConfig.keyToken, result.token);

                                    Global.username = unameController.text;

                                    print("保存username->${Global.username}");

                                    if (refreshToken) {
                                      EventBusManager.eventBus.fire(ReLoginEvent());
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
                      ),
                    ),
                  ),
                )
              ],
            )),
        onWillPop: () async => false);
  }
}

class LoginArgs {
  final bool refreshToken;

  LoginArgs(this.refreshToken);
}
