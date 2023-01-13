import 'package:cloud_driver/model/entity/base_entity.dart';
import 'package:json_annotation/json_annotation.dart';
part 'common_entity.g.dart';
@JsonSerializable()
class CommonEntity extends BaseEntity<dynamic>{

  CommonEntity(String code, String message) : super(code, message,null);

  factory CommonEntity.fromJson(Map<String, dynamic> json) => _$CommonEntityFromJson(json);

  Map<String,dynamic> toJson() => _$CommonEntityToJson(this);
}
