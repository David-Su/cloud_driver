import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/manager/event_bus_manager.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/model/entity/login_entity.dart';
import 'package:cloud_driver/model/event/event.dart';
import 'package:cloud_driver/model/global.dart';
import 'package:cloud_driver/page/login/login_page_bloc.dart';
import 'package:cloud_driver/page/login/login_page_event.dart';
import 'package:cloud_driver/page/login/login_page_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/entity/base_entity.dart';
import '../../util/util.dart';

class LoginPage extends StatefulWidget {
  final LoginArgs? _args;

  const LoginPage({super.key, LoginArgs? args}) : _args = args;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _platformAdapter = PlatformAdapter();
  late final LoginPageBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = LoginPageBloc(widget._args);
    _bloc.add(InitEvent(context));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _bloc,
      child: MultiBlocListener(
        listeners: [_buildPopEventListener(), _buildToFilePageEventListener()],
        child: Scaffold(
          body: BlocBuilder<LoginPageBloc, LoginPageState>(
            builder: (BuildContext context, LoginPageState state) {
              if (state.showLoginUi) {
                return kIsWeb
                    ? _buildWebPage(context)
                    : _buildMobilePage(context);
              } else {
                return Container(
                  alignment: Alignment.center,
                  child: Image.asset("graphics/ic_launcher.png"),
                );
              }
            },
            buildWhen: (pre, cur) {
              return pre.showLoginUi != cur.showLoginUi;
            },
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
        ),
      ),
    );
  }

  Widget _buildMobilePage(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset("graphics/ic_login.svg"),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: Card(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 50.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildTitle(),
                    ),
                    SizedBox(
                      height: 60.w,
                    ),
                    TextField(
                        controller: _bloc.unameController,
                        decoration: const InputDecoration(
                          labelText: "用户名",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        )),
                    SizedBox(
                      height: 40.w,
                    ),
                    TextField(
                        controller: _bloc.pswController,
                        decoration: const InputDecoration(
                          labelText: "密码",
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                        )),
                    SizedBox(
                      height: 60.w,
                    ),
                    Container(
                        constraints: const BoxConstraints.tightFor(
                            width: double.infinity),
                        child: FilledButton.icon(
                          onPressed: () => _bloc.add(LoginEvent(context)),
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
    );
  }

  BlocBuilder<LoginPageBloc, LoginPageState> _buildTitle() {
    return BlocBuilder<LoginPageBloc, LoginPageState>(
      builder: (BuildContext context, state) {
        return Text(
          state.title,
          style: Theme.of(context).textTheme.titleLarge,
        );
      },
      buildWhen: (pre, cur) {
        return pre.title != cur.title;
      },
    );
  }

  Widget _buildWebPage(BuildContext context) {
    //登录框的宽度
    final webScreenWidth = _platformAdapter.webGetScreenSize()?.width ?? 0;
    final loginFrameWidth = webScreenWidth / 5;
    final bgWidth = webScreenWidth / 2;

    return PopScope(
      child: Stack(
        children: [
          Center(
            // child: Image.network(
            //   "assets/graphics/ic_login.svg",
            //   width: bgWidth,
            //   fit: BoxFit.fitWidth,
            // ),
            child: SvgPicture.asset(
              "graphics/ic_login.svg",
              width: bgWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          // Align(alignment: Alignment.topCenter, child: Image.network("web/icons/ic_login.svg")),
          Center(
            child: SingleChildScrollView(
              child: Card(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  width: loginFrameWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTitle(),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextField(
                          controller: _bloc.unameController,
                          decoration: const InputDecoration(
                            labelText: "用户名",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          )),
                      const SizedBox(
                        height: 20,
                      ),
                      TextField(
                          controller: _bloc.pswController,
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
                          constraints: const BoxConstraints.tightFor(
                              width: double.infinity),
                          child: FilledButton.icon(
                            onPressed: () => _bloc.add(LoginEvent(context)),
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
      ),
      canPop: false,
    );
  }

  _buildPopEventListener() {
    return BlocListener<LoginPageBloc, LoginPageState>(
      listener: (BuildContext context, LoginPageState state) {
        Navigator.of(context).pop();
      },
      listenWhen: (pre, cur) {
        return cur.popEvent != null;
      },
    );
  }

  _buildToFilePageEventListener() {
    return BlocListener<LoginPageBloc, LoginPageState>(
      listener: (BuildContext context, LoginPageState state) {
        Navigator.of(context).popAndPushNamed("/file");
      },
      listenWhen: (pre, cur) {
        return cur.toFilePageEvent != null;
      },
    );
  }
}

class LoginArgs {
  final LoginReason loginReason;

  LoginArgs(this.loginReason);
}

enum LoginReason {
  init,
  refreshToken,
  logout,
}
