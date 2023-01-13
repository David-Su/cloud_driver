import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_file_entity.g.dart';

@JsonSerializable()
class ListFileEntity extends BaseEntity<ListFileResult> {
  ListFileEntity(String code, String message, ListFileResult? result)
      : super(code, message, result);

  factory ListFileEntity.fromJson(Map<String, dynamic> json) =>
      _$ListFileEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ListFileEntityToJson(this);
}

@JsonSerializable()
class ListFileResult {
  List<ListFileResult>? children;
  bool isDir;
  String name;
  int? size;
  String? previewImg;

  //当前列表滚动位置，非网络数据
  @JsonKey(ignore: true)
  double? position;

  //数据大小显示，非网络数据
  @JsonKey(ignore: true)
  String displaySize = "";

  //previewImg生成的完整url
  @JsonKey(ignore: true)
  String? previewImgUrl;

  ListFileResult(
      this.children, this.isDir, this.name, this.size, this.previewImg);

  factory ListFileResult.fromJson(Map<String, dynamic> json) =>
      _$ListFileResultFromJson(json);

  Map<String, dynamic> toJson() => _$ListFileResultToJson(this);
}
