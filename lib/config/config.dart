class ChannelConfig {
  ChannelConfig._internal();

  static const channel = String.fromEnvironment("CHANNEL");
  static const channelInternet = "internet"; //公网
  static const channelInternetProxy = "internetProxy"; //公网代理内网
  static const channelIntranet = "intranet"; //内网
}

class NetworkConfig {
  NetworkConfig._internal();

  static final String urlBase = "http://$_host/CloudDriver";
  static final String wsUrlBase = "ws://$_host/CloudDriver";
  static const String apiLogin = "/login";
  static const String apiListFile = "/listfile";
  static const String apiCreateDir = "/createdir";
  static const String apiDeleteFile = "/deletefile";
  static const String apiDownloadFile = "/downloadfile";
  static const String apiUploadFile = "/uploadfile";
  static const String apiRenameFile = "/renamefile";
  static const String apiWsUploadTasks = "/websocket/uploadtasks";
  static const int timeoutConnect = 5000;
  static const int timeoutReceive = 5000;

  static const String codeOk = "0000";

  //token过期
  static const String codeTokenTimeOut = "0002";

  //账号或密码错误
  static const String codeUnOrPwError = "0003";

  //创建文件目录失败
  static const String codeCreateDirFail = "0004";

  static String get _host {
    switch (ChannelConfig.channel) {
      case ChannelConfig.channelInternet:
        //todo
        return "";
      case ChannelConfig.channelInternetProxy:
        return "fqym.top:8080";
      case ChannelConfig.channelIntranet:
        return "192.168.0.250:8080";
    }
    return "fqym.top:8080";
    // return "192.168.20.152:8080";
  }
}

class SpConfig {
  SpConfig._internal();

  static const String keyToken = "key_token";
  static const String keyUsername = "key_username";
}
