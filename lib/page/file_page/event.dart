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

//创建目录
class CreateDirEvent extends FilePageEvent {
  final String name;

  const CreateDirEvent(this.name);
}

//删除文件
class DeleteFileEvent extends FilePageEvent {
  final String name;

  const DeleteFileEvent(this.name);
}

//文件列表滚动事件
class FileListScrollEvent extends FilePageEvent {
  final double position;

  FileListScrollEvent(this.position);
}

//刷新所有数据
class RefreshDataEvent extends FilePageEvent {}

//下载服务器文件
class DownloadFileEvent extends FilePageEvent {
  final int index;

  DownloadFileEvent(this.index); //文件在列表中的索引
}

//上传文件
class UploadFileEvent extends FilePageEvent {
  UploadFileEvent(); //文件在列表中的索引
}

//播放视频
class PlayVideoEvent extends FilePageEvent {
  static const typePotPlayer = 1;
  final int type;
  final int index;
  PlayVideoEvent(this.type, this.index);
}
