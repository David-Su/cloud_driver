import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'list_file_entity.g.dart';
@JsonSerializable()
class ListFileEntity extends BaseEntity<ListFileResult>{
  ListFileEntity(String code, String message, ListFileResult? result) : super(code, message, result);

  factory ListFileEntity.fromJson(Map<String, dynamic> json) => _$ListFileEntityFromJson(json);

  Map<String,dynamic> toJson() => _$ListFileEntityToJson(this);
}
@JsonSerializable()
class ListFileResult{
    List<ListFileResult>? children;
    bool isDir;
    String name;

    ListFileResult(this.children, this.isDir, this.name);

    factory ListFileResult.fromJson(Map<String, dynamic> json) => _$ListFileResultFromJson(json);

    Map<String,dynamic> toJson() => _$ListFileResultToJson(this);

}