class LoginPageState {
  bool showLoginUi = false;
  String title = "";
  Object? popEvent;
  Object? toFilePageEvent;

  LoginPageState clone() {
    return LoginPageState()..showLoginUi = showLoginUi;
  }
}
