// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_file_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteFileEntity _$DeleteFileEntityFromJson(Map<String, dynamic> json) =>
    DeleteFileEntity(
      json['code'] as String,
      json['message'] as String,
      DeleteFileResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DeleteFileEntityToJson(DeleteFileEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };

DeleteFileResult _$DeleteFileResultFromJson(Map<String, dynamic> json) =>
    DeleteFileResult();

Map<String, dynamic> _$DeleteFileResultToJson(DeleteFileResult instance) =>
    <String, dynamic>{};
