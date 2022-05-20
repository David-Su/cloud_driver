import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'create_dir_entity.g.dart';
@JsonSerializable()
class CreateDirEntity extends BaseEntity<dynamic>{

  CreateDirEntity(String code, String message) : super(code, message,null);

  factory CreateDirEntity.fromJson(Map<String, dynamic> json) => _$CreateDirEntityFromJson(json);

  Map<String,dynamic> toJson() => _$CreateDirEntityToJson(this);
}
