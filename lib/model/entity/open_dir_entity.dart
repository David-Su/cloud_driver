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
  List<OpenDirChild>? children;
  int? size;

  //当前列表滚动位置，非网络数据
  @JsonKey(ignore: true)
  double? position;

  OpenDirResult(this.name, this.children, this.size);

  factory OpenDirResult.fromJson(Map<String, dynamic> json) =>
      _$OpenDirResultFromJson(json);

  Map<String, dynamic> toJson() => _$OpenDirResultToJson(this);
}

@JsonSerializable()
class OpenDirChild {
  bool? isDir;
  String? name;
  int? size;
  String? previewImg;

  //previewImg生成的完整url
  @JsonKey(ignore: true)
  String? previewImgUrl;

  //选择状态
  @JsonKey(ignore: true)
  bool isSelected = false;

  //数据大小显示，非网络数据
  @JsonKey(ignore: true)
  String displaySize = "";

  OpenDirChild(this.isDir, this.name, this.size, this.previewImg);

  factory OpenDirChild.fromJson(Map<String, dynamic> json) =>
      _$OpenDirChildFromJson(json);

  Map<String, dynamic> toJson() => _$OpenDirChildToJson(this);
}
