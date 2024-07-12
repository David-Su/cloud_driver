import 'package:flutter/widgets.dart';

abstract class LoginPageEvent {}

class LoginEvent extends LoginPageEvent {
  final BuildContext context;

  LoginEvent(this.context);
}

class InitEvent extends LoginPageEvent {
  final BuildContext context;

  InitEvent(this.context);
}
