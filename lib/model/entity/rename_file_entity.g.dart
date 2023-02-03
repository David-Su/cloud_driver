// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_file_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RenameFileEntity _$RenameFileEntityFromJson(Map<String, dynamic> json) =>
    RenameFileEntity(
      json['code'] as String,
      json['message'] as String,
    )..result = json['result'];

Map<String, dynamic> _$RenameFileEntityToJson(RenameFileEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };
