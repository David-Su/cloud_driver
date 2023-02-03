import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';

class FilePageState {
  //当前路径
  List<ListFileResult> paths = [];

  //当前路径下的文件
  List<ListFileResult> children = [];

  //文件列表的滑动位置
  double fileListPosition = 0;

  //是否弹出上传进度dialog
  bool showUploadProgressDialog = false;

  //是否弹出等待服务器dialog
  bool showWaitServerDialog = false;

  //当前文件目录选择路径
  List<ListFileResult> dirChoosePaths = [];

  //上传进度
  double uploadProgress = 0;

  //上传速度
  String displaySpeed = "";
  double speed = 0.0;

  //是否为表格视图
  bool isGridView = true;

  //进行中的任务
  List<UpdateTaskEntity> updateTasks= [];

  FilePageState clone() {
    return FilePageState()
      ..paths = paths
      ..children = children
      ..fileListPosition = fileListPosition
      ..showUploadProgressDialog = showUploadProgressDialog
      ..uploadProgress = uploadProgress
      ..displaySpeed = displaySpeed
      ..speed = speed
      ..isGridView = isGridView
      ..updateTasks = updateTasks
      ..dirChoosePaths = dirChoosePaths
    ;
  }
}
