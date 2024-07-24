import 'dart:async';
import 'dart:math';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/manager/event_bus_manager.dart';
import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:cloud_driver/model/entity/login_entity.dart';
import 'package:cloud_driver/model/event/event.dart';
import 'package:cloud_driver/model/global.dart';
import 'package:cloud_driver/page/login/login_page_event.dart';
import 'package:cloud_driver/page/login/login_page_state.dart';
import 'package:cloud_driver/util/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_driver/page/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPageBloc extends Bloc<LoginPageEvent, LoginPageState> {
  final unameController = TextEditingController();
  final pswController = TextEditingController();
  final LoginArgs? _args;

  LoginPageBloc(LoginArgs? arg)
      : _args = arg,
        super(LoginPageState()) {
    on<LoginEvent>(_login);
    on<InitEvent>(_init);
  }

  FutureOr<void> _login(LoginEvent event, Emitter<LoginPageState> emit) async {
    await _loginInternal(event.context, true, emit);
  }

  FutureOr<void> _init(InitEvent event, Emitter<LoginPageState> emit) async {
    emit(state.clone()..showLoginUi = false);
    final loginResult = _args?.loginReason ?? LoginReason.init;
    if (loginResult == LoginReason.refreshToken) {
      emit(state.clone()..title = "重新登陆");
    } else {
      emit(state.clone()..title = "登陆云盘");
    }
    final sp = await SharedPreferences.getInstance();
    switch (loginResult) {
      case LoginReason.init:
      case LoginReason.refreshToken:
        final localUsername = sp.getString(SpConfig.keyUsername);
        final localPsw = sp.getString(SpConfig.keyPsw);

        unameController.text = localUsername ?? "";
        pswController.text = localPsw ?? "";

        final autoLoginSuccess = localUsername?.isNotEmpty == true &&
            localPsw?.isNotEmpty == true &&
            await _loginInternal(event.context, false, emit);

        emit(state.clone()..showLoginUi = !autoLoginSuccess);

        break;
      case LoginReason.logout:
        await Future.wait(
            [sp.remove(SpConfig.keyUsername), sp.remove(SpConfig.keyPsw)]);
        unameController.text = "";
        pswController.text = "";

        emit(state.clone()..showLoginUi = true);
        break;
    }
  }

  FutureOr<bool> _loginInternal(BuildContext context, bool isShowDialog,
      Emitter<LoginPageState> emit) async {
    final username = unameController.value.text;
    final password = pswController.value.text;

    final futures = await Future.wait([
      SharedPreferences.getInstance(),
      DioManager().doPost(
          api: NetworkConfig.apiLogin,
          data: {"username": username, "password": password},
          transformer: (json) => LoginEntity.fromJson(json),
          context: context,
          isShowDialog: isShowDialog,
          interceptor: (BaseEntity<LoginResult> baseEntity,
              DefaultHandle<LoginResult> defaultHandler) {
            switch (baseEntity.code) {
              case NetworkConfig.codeOk:
                return baseEntity;
              default:
                Util.showDefaultToast(baseEntity.message);
                break;
            }
            return null;
          })
    ]);

    final sp = futures[0] as SharedPreferences;

    final result =
        Util.getBaseEntityResultOrNull(futures[1] as BaseEntity<LoginResult?>?);

    if (result == null) return false;

    sp.setString(SpConfig.keyToken, result.token);
    sp.setString(SpConfig.keyUsername, username);
    sp.setString(SpConfig.keyPsw, password);

    Global.username = username;

    print("保存username->${Global.username}");

    final refreshToken = _args?.loginReason == LoginReason.refreshToken;

    if (refreshToken) {
      EventBusManager.eventBus.fire(ReLoginEvent());
      emit(state.clone()..popEvent = Object());
    } else {
      emit(state.clone()..toFilePageEvent = Object());
    }

    return true;
  }
}
