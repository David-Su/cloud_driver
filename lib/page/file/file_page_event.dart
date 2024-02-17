import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/entity/update_task_entity.dart';

abstract class FilePageEvent {
  const FilePageEvent();
}

class InitEvent extends FilePageEvent {}

//回退到前一目录
class BackEvent extends FilePageEvent {}

//去到下一目录
class ForwardEvent extends FilePageEvent {
  final int index;

  ForwardEvent(this.index); //文件在列表中的索引
}

class SelectEvent extends FilePageEvent {
  final int index;

  SelectEvent(this.index); //文件在列表中的索引
}

//创建目录
class CreateDirEvent extends FilePageEvent {
  final String name;

  const CreateDirEvent(this.name);
}

//删除文件
class DeleteFileEvent extends FilePageEvent {
  final List<String> names;

  DeleteFileEvent(this.names);
}

//文件列表滚动事件
class FileListScrollEvent extends FilePageEvent {
  final double position;

  FileListScrollEvent(this.position);
}

//刷新所有数据
class RefreshDataEvent extends FilePageEvent {
  final Completer<void>? completer;

  RefreshDataEvent(this.completer);
}

//下载服务器文件
class DownloadFileEvent extends FilePageEvent {
  //文件在列表中的索引
  final int index;

  DownloadFileEvent(this.index);
}

//上传文件
class UploadFileEvent extends FilePageEvent {
  final bool dir;

  UploadFileEvent(this.dir); //文件在列表中的索引
}

//播放视频
class PlayVideoEvent extends FilePageEvent {
  static const typePotPlayer = 1;
  final int type;
  final int index;

  PlayVideoEvent(this.type, this.index);
}

class OpenFileEvent extends FilePageEvent {
  final int index;
  final BuildContext context;
  OpenFileEvent(this.index,this.context);
}

//弹出进度对话框完成
class ShowProgressDialogSuccessEvent extends FilePageEvent {}

//弹出等待服务器对话框完成
class ShowWaitServerDialogSuccessEvent extends FilePageEvent {}

//切换表格或列表视图
class SwitchViewEvent extends FilePageEvent {}

//更新进行中的任务
class UpdateTasksEvent extends FilePageEvent {
  final List<UpdateTaskEntity> updateTasks;

  UpdateTasksEvent(this.updateTasks);
}

class RenameEvent extends FilePageEvent {
  //文件在列表中的索引
  final int index;
  final String newName;

  RenameEvent(this.index, this.newName);
}

class ShowDirChooseDialogEvent extends FilePageEvent {
  ShowDirChooseDialogEvent();
}

//去到下一目录
class DirChooseForwardEvent extends FilePageEvent {
  //文件在列表中的索引
  final int index;

  DirChooseForwardEvent(this.index);
}

//去到下一目录
class DirChooseBackwardEvent extends FilePageEvent {
  DirChooseBackwardEvent();
}

//去到上一目录
class MoveFileEvent extends FilePageEvent {
  final int index;

  MoveFileEvent(this.index);
}

//取消选择模式事件
class CloseSelectModeEvent extends FilePageEvent {}
