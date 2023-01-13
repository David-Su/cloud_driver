// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommonEntity _$CommonEntityFromJson(Map<String, dynamic> json) => CommonEntity(
      json['code'] as String,
      json['message'] as String,
    )..result = json['result'];

Map<String, dynamic> _$CommonEntityToJson(CommonEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };
