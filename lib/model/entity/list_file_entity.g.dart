// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_file_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListFileEntity _$ListFileEntityFromJson(Map<String, dynamic> json) =>
    ListFileEntity(
      json['code'] as String,
      json['message'] as String,
      json['result'] == null
          ? null
          : ListFileResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ListFileEntityToJson(ListFileEntity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
    };

ListFileResult _$ListFileResultFromJson(Map<String, dynamic> json) =>
    ListFileResult(
      (json['children'] as List<dynamic>?)
          ?.map((e) => ListFileResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['isDir'] as bool,
      json['name'] as String,
    );

Map<String, dynamic> _$ListFileResultToJson(ListFileResult instance) =>
    <String, dynamic>{
      'children': instance.children,
      'isDir': instance.isDir,
      'name': instance.name,
    };
