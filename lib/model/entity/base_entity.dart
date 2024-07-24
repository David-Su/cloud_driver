import 'package:cloud_driver/config/config.dart';

class BaseEntity<T> {
  String code;
  String message;
  T? result;

  BaseEntity(this.code, this.message, this.result);

  bool get isOk {
    return code == NetworkConfig.codeOk;
  }
}
