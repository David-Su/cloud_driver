import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:cloud_driver/model/entity/open_dir_entity.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';

class FilePageState {
  //当前路径
  List<OpenDirResult> paths = [];

  //当前路径下的文件
  List<OpenDirChild> children = [];

  //文件列表的滑动位置
  double fileListPosition = 0;

  //是否弹出上传进度dialog
  bool showUploadProgressDialog = false;

  //是否弹出等待服务器dialog
  bool showWaitServerDialog = false;

  //打开在线播放视频界面
  OpenVideoPageEvent? openVideoPageEvent;

  //当前文件目录选择路径
  List<OpenDirResult> dirChoosePaths = [];

  //上传进度
  double uploadProgress = 0;

  //上传速度
  String displaySpeed = "";
  double speed = 0.0;

  //是否为表格视图
  bool isGridView = true;

  //进行中的任务
  List<UpdateTaskEntity> updateTasks = [];

  //选择文件模式
  bool selectMode = false;

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
      ..selectMode = selectMode;
  }
}

class OpenVideoPageEvent {
  final String url;

  OpenVideoPageEvent(this.url);
}