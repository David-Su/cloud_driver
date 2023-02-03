import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'rename_file_entity.g.dart';
@JsonSerializable()
class RenameFileEntity extends BaseEntity<dynamic>{

  RenameFileEntity(String code, String message) : super(code, message,null);

  factory RenameFileEntity.fromJson(Map<String, dynamic> json) => _$RenameFileEntityFromJson(json);

  Map<String,dynamic> toJson() => _$RenameFileEntityToJson(this);
}
