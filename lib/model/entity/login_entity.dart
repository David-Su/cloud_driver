import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'login_entity.g.dart';
@JsonSerializable()
class LoginEntity extends BaseEntity<LoginResult>{
  LoginEntity(String code, String message, LoginResult? result) : super(code, message, result);

  factory LoginEntity.fromJson(Map<String, dynamic> json) => _$LoginEntityFromJson(json);

  Map<String,dynamic> toJson() => _$LoginEntityToJson(this);

}
@JsonSerializable()
class LoginResult{
  String token;

  LoginResult(this.token);

  factory LoginResult.fromJson(Map<String, dynamic> json) => _$LoginResultFromJson(json);

  Map<String,dynamic> toJson() => _$LoginResultToJson(this);

}