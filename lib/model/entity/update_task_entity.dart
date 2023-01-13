import 'package:json_annotation/json_annotation.dart';
part 'update_task_entity.g.dart';
/**
 * @Author SuK
 * @Des
 * @Date 2022/12/5
 */
@JsonSerializable()
class UpdateTaskEntity {
  final String? path;
  final double? progress;
  final int? speed;

  //网速大小显示，非网络数据
  @JsonKey(ignore: true)
  String displaySpeed = "";

  UpdateTaskEntity(this.path, this.progress, this.speed);

  factory UpdateTaskEntity.fromJson(Map<String, dynamic> json) => _$UpdateTaskEntityFromJson(json);

  Map<String,dynamic> toJson() => _$UpdateTaskEntityToJson(this);
}
