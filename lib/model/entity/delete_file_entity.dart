import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'delete_file_entity.g.dart';
@JsonSerializable()
class DeleteFileEntity extends BaseEntity<dynamic>{
  // DeleteFileEntity(String code, String message, DeleteFileResult result) : super(code, message, result);

  DeleteFileEntity(String code, String message) : super(code, message,null);

  factory DeleteFileEntity.fromJson(Map<String, dynamic> json) => _$DeleteFileEntityFromJson(json);

  Map<String,dynamic> toJson() => _$DeleteFileEntityToJson(this);
}
// @JsonSerializable()
// class DeleteFileResult{
//
//   DeleteFileResult();
//
//   factory DeleteFileResult.fromJson(Map<String, dynamic>? json) => _$DeleteFileResultFromJson(json);
//
//   Map<String,dynamic> toJson() => _$DeleteFileResultToJson(this);
//
// }