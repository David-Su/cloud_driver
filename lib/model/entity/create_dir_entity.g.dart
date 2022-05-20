// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_dir_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateDirEntity _$CreateDirEntityFromJson(Map<String, dynamic> json) =>
    CreateDirEntity(
      json['code'] as String,
      json['message'] as String,
    )..result = json['result'];

Map<String, dynamic> _$CreateDirEntityToJson(CreateDirEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };
