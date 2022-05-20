class NetworkConfig {
  static const String urlBase = "http://127.0.0.1:8080/CloudDriver";
  // static const String urlBase = "http://8.218.97.215:8080/CloudDriver";
  static const String apiLogin = "/login";
  static const String apiListFile = "/listfile";
  static const String apiCreateDir = "/createdir";
  static const String apiDeleteFile = "/deletefile";
  static const String apiDownloadFile = "/downloadfile";
  static const String apiUploadFile = "/uploadfile";
  static const int timeoutConnect = 2000;
  static const int timeoutReceive = 5000;

  static const String codeOk = "0000";
  //token过期
  static const String codeTokenTimeOut= "0002";
  //账号或密码错误
  static const String codeUnOrPwError= "0003";
  //创建文件目录失败
  static const String codeCreateDirFail= "0004";
}

class SpConfig {
  static const String keyToken= "key_token";
}
