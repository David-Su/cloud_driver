// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_task_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateTaskEntity _$UpdateTaskEntityFromJson(Map<String, dynamic> json) =>
    UpdateTaskEntity(
      json['path'] as String?,
      (json['progress'] as num?)?.toDouble(),
      json['speed'] as int?,
    );

Map<String, dynamic> _$UpdateTaskEntityToJson(UpdateTaskEntity instance) =>
    <String, dynamic>{
      'path': instance.path,
      'progress': instance.progress,
      'speed': instance.speed,
    };
