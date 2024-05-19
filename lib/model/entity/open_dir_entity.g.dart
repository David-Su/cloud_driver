// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_dir_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenDirEntity _$OpenDirEntityFromJson(Map<String, dynamic> json) =>
    OpenDirEntity(
      json['code'] as String,
      json['message'] as String,
      json['result'] == null
          ? null
          : OpenDirResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OpenDirEntityToJson(OpenDirEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };

OpenDirResult _$OpenDirResultFromJson(Map<String, dynamic> json) =>
    OpenDirResult(
      json['name'] as String?,
      (json['children'] as List<dynamic>?)
          ?.map((e) => DirCloudFileChild.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OpenDirResultToJson(OpenDirResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'children': instance.children,
      'size': instance.size,
    };

DirCloudFileChild _$DirCloudFileChildFromJson(Map<String, dynamic> json) =>
    DirCloudFileChild(
      json['isDir'] as bool?,
      json['name'] as String?,
      (json['size'] as num?)?.toInt(),
      json['previewImg'] as String?,
    );

Map<String, dynamic> _$DirCloudFileChildToJson(DirCloudFileChild instance) =>
    <String, dynamic>{
      'isDir': instance.isDir,
      'name': instance.name,
      'size': instance.size,
      'previewImg': instance.previewImg,
    };
