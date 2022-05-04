// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginEntity _$LoginEntityFromJson(Map<String, dynamic> json) => LoginEntity(
      json['code'] as String,
      json['message'] as String,
      json['result'] == null
          ? null
          : LoginResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginEntityToJson(LoginEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };

LoginResult _$LoginResultFromJson(Map<String, dynamic> json) => LoginResult(
      json['token'] as String,
    );

Map<String, dynamic> _$LoginResultToJson(LoginResult instance) =>
    <String, dynamic>{
      'token': instance.token,
    };
