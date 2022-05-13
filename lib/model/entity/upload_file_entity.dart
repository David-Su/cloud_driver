import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'upload_file_entity.g.dart';
@JsonSerializable()
class UploadFileEntity extends BaseEntity<dynamic>{
  // DeleteFileEntity(String code, String message, DeleteFileResult result) : super(code, message, result);

  UploadFileEntity(String code, String message) : super(code, message,null);

  factory UploadFileEntity.fromJson(Map<String, dynamic> json) => _$UploadFileEntityFromJson(json);

  Map<String,dynamic> toJson() => _$UploadFileEntityToJson(this);
}
