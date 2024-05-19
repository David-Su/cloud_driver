import 'package:json_annotation/json_annotation.dart';

import 'base_entity.dart';

part 'open_dir_entity.g.dart';

@JsonSerializable()
class OpenDirEntity extends BaseEntity<OpenDirResult> {
  OpenDirEntity(super.code, super.message, super.result);

  factory OpenDirEntity.fromJson(Map<String, dynamic> json) =>
      _$OpenDirEntityFromJson(json);

  Map<String, dynamic> toJson() => _$OpenDirEntityToJson(this);
}

@JsonSerializable()
class OpenDirResult {
  String? name;
  List<DirCloudFileChild>? children;
  int? size;

  OpenDirResult(this.name, this.children, this.size);

  factory OpenDirResult.fromJson(Map<String, dynamic> json) =>
      _$OpenDirResultFromJson(json);

  Map<String, dynamic> toJson() => _$OpenDirResultToJson(this);
}

@JsonSerializable()
class DirCloudFileChild {
  bool? isDir;
  String? name;
  int? size;
  String? previewImg;

  DirCloudFileChild(this.isDir, this.name, this.size, this.previewImg);

  factory DirCloudFileChild.fromJson(Map<String, dynamic> json) =>
      _$DirCloudFileChildFromJson(json);

  Map<String, dynamic> toJson() => _$DirCloudFileChildToJson(this);
}
