// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_file_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadFileEntity _$UploadFileEntityFromJson(Map<String, dynamic> json) =>
    UploadFileEntity(
      json['code'] as String,
      json['message'] as String,
    )..result = json['result'];

Map<String, dynamic> _$UploadFileEntityToJson(UploadFileEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };
