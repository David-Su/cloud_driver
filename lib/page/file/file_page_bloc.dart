import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/manager/event_bus_manager.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/model/entity/create_dir_entity.dart';
import 'package:cloud_driver/model/entity/delete_file_entity.dart';
import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:cloud_driver/model/entity/open_dir_entity.dart';
import 'package:cloud_driver/model/entity/rename_file_entity.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';
import 'package:cloud_driver/model/event/event.dart';
import 'package:cloud_driver/util/util.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'file_page_event.dart';
import 'file_page_state.dart';

class FilePageBloc extends Bloc<FilePageEvent, FilePageState> {
  final BuildContext _context;
  final _platformAdapter = PlatformAdapter();
  WebSocketChannel? _webSocketChannel;
  Completer<void>? _progressDialogCompleter;
  Completer<void>? _waitServerDialogCompleter;
  StreamSubscription? _reLoginSubscription;
  bool _autoReConnWs = true;

  FilePageBloc(this._context) : super(FilePageState()) {
    on<InitEvent>(_init);
    on<BackEvent>(_back);
    on<ForwardEvent>(_forward);
    on<CreateDirEvent>(_createDir);
    on<DeleteFileEvent>(_deleteFile);
    on<FileListScrollEvent>(_fileListScroll);
    on<RefreshDataEvent>(_refreshData);
    on<DownloadFileEvent>(_downloadFile);
    on<UploadFileEvent>(_uploadFile);
    on<PlayVideoEvent>(_playVideo);
    on<ShowProgressDialogSuccessEvent>(_showProgressDialogSuccess);
    on<ShowWaitServerDialogSuccessEvent>(_showWaitServerDialogSuccess);
    on<SwitchViewEvent>(_switchView);
    on<UpdateTasksEvent>(_updateTasks);
    on<RenameEvent>(_rename);
    on<DirChooseForwardEvent>(_dirChooseForward);
    on<ShowDirChooseDialogEvent>(_showDirChooseDialog);
    on<MoveFileEvent>(_moveFileEvent);
    on<DirChooseBackwardEvent>(_dirChooseBackward);
    on<SelectEvent>(_selectEvent);
    on<CloseSelectModeEvent>(_closeSelectModeEvent);
    on<OpenFileEvent>(_openFile);

    Future(() async {
      //WebSocket监听服务端消息
      await _wsConn();
      //监听事件
      _reLoginSubscription =
          EventBusManager.eventBus.on<ReLoginEvent>().listen((event) async {
        final formerAutoReConnWs = _autoReConnWs;
        _autoReConnWs = false;
        await _wsConn();
        _autoReConnWs = formerAutoReConnWs;
      });
    });
  }

  Future<void> _wsConn() async {
    await _webSocketChannel?.sink.close();

    final token = await SharedPreferences.getInstance()
        .then((value) => value.getString(SpConfig.keyToken));

    final channel = WebSocketChannel.connect(Uri.parse(
        "${NetworkConfig.wsUrlBase}${NetworkConfig.apiWsUploadTasks}?token=$token"));

    await channel.ready;

    channel.stream.listen((event) {
      final Map<String, dynamic> eventJson = json.decode(event.toString());

      final dataType = eventJson["dataType"] as int;
      final data = eventJson["data"];

      switch (dataType) {
        case 0: //update
          {
            final tasks = (data as List<dynamic>).map((e) {
              final entity = UpdateTaskEntity.fromJson(e);
              entity.displaySpeed =
                  "${_getDisplaySize(entity.speed?.toDouble() ?? 0)}/s";
              return entity;
            }).toList();

            add(UpdateTasksEvent(tasks));

            break;
          }
        case 1: //remove
          {
            final removePath = (data as String);
            state.updateTasks
                .removeWhere((element) => element.path == removePath);
            add(UpdateTasksEvent(List.of(state.updateTasks)));
          }
      }
    }, onError: (error) async {
      debugPrint('ws onError $error');
      await _wsReConn();
      Util.showDefaultToast("与服务器断开连接，请重新登录");
    }, onDone: () async {
      debugPrint('ws onDone');
      await _wsReConn();
    });

    channel.sink.add("hello from flutter");

    _webSocketChannel = channel;
  }

  Future _wsReConn() async {
    //等到上一次重连结束
    if (_autoReConnWs && _lastWsReConnJob?.isCompleted == true) {
      //与上一次重连的最小时间间隔为minSpan
      await Future(() async {
        final lastTime = _lastWsReConnTime;
        if (lastTime != null) {
          const minSpan = 500;
          final nowTime = DateTime.now().millisecondsSinceEpoch;
          final span = nowTime - lastTime;
          final int delay;
          if (span > minSpan) {
            delay = minSpan;
          } else if (span > 0) {
            delay = minSpan - span;
          } else {
            delay = 0;
          }
          await Future.delayed(Duration(milliseconds: delay));
        }
      });

      final completer = Completer();
      await _wsConn();
      _lastWsReConnTime = DateTime.now().millisecondsSinceEpoch;
      _lastWsReConnJob = completer;
      completer.complete();
    }
  }

  int? _lastWsReConnTime;
  Completer? _lastWsReConnJob;

  @override
  Future<void> close() async {
    super.close();
    _autoReConnWs = false;
    _webSocketChannel?.sink.close();
    _reLoginSubscription?.cancel();
  }

  Future<void> _init(InitEvent event, Emitter<FilePageState> emit) async {
    final openFile = await _openDir(["."]);

    if (openFile == null) return;

    emit(state.clone()
      ..paths = [openFile]
      ..children = openFile.children ?? []);
  }

  FutureOr<void> _back(BackEvent event, Emitter<FilePageState> emit) async{
    final hadSelected = state.children
            .firstWhereOrNull((element) => element.isSelected == true) !=
        null;

    if (hadSelected) {
      final newChildren = state.children.toList()
        ..forEach((element) {
          element.isSelected = false;
        });
      emit(state.clone()..children = newChildren);
      _emitSelectModeState(emit);
    } else {
      final paths = state.paths.toList();
      if (paths.length > 1) {
        paths.removeAt(paths.length - 1);
        emit(state.clone()..paths = paths);
        await _refresh(emit);
      }
    }
  }

  FutureOr<void> _createDir(
      CreateDirEvent event, Emitter<FilePageState>? emit) async {
    final name = event.name;

    final paths = _getWholePathList(fileName: name);

    final createDirEntity = await DioManager().doPost(
        api: NetworkConfig.apiCreateDir,
        data: {"paths": paths},
        transformer: (Map<String, dynamic> json) =>
            CreateDirEntity.fromJson(json),
        context: _context);

    if (Util.handleBaseEntity(createDirEntity) == null) return;

    if (emit != null) {
      await _refresh(emit);
    }
  }

  FutureOr<void> _deleteFile(
      DeleteFileEvent event, Emitter<FilePageState> emit) async {
    final futures = event.names.map((name) async {
      final paths = _getWholePathList(fileName: name);
      return await DioManager().doPost(
          api: NetworkConfig.apiDeleteFile,
          data: {"paths": paths},
          transformer: (json) => DeleteFileEntity.fromJson(json),
          context: _context);
    });

    final results = await Future.wait(futures);

    if (results.every((element) => element == null)) {
      return;
    }

    await _refresh(emit);
  }

  Future<void> _refresh(Emitter<FilePageState> emit,
      {bool isShowDialog = true}) async {
    final openFile = await _openDir(_getWholePathList());

    if (openFile == null) return;

    emit(state.clone()..children = openFile.children ?? []);
  }

  Future<OpenDirResult?> _openDir(List<String> paths,
      {bool isShowDialog = true}) async {
    final openDirEntity = await DioManager().doPost(
        api: NetworkConfig.apiOpenDir,
        data: {"paths": paths},
        transformer: (json) => OpenDirEntity.fromJson(json),
        context: _context,
        isShowDialog: isShowDialog);

    final openFile = Util.handleBaseEntity(openDirEntity);

    if (openFile == null) return null;

    final openFileChildren = openFile.children;

    openFileChildren?.sort((OpenDirChild a, OpenDirChild b) {
      if (a.isDir == b.isDir) {
        return (b.size ?? 0).compareTo(a.size ?? 0);
      }
      if (a.isDir == true) {
        return -1;
      } else {
        return 1;
      }
    });

    assemblePreviewImgUrl(openFile);

    return openFile;
  }

  Future<void> assemblePreviewImgUrl(OpenDirResult openDirResult) async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(SpConfig.keyToken);

    openDirResult.children?.forEach((element) {
      final previewImg = element.previewImg;
      if (previewImg != null) {
        element.previewImgUrl =
            "${NetworkConfig.urlBase}$previewImg&token=$token";
      }
    });
  }

  void _fileListScroll(FileListScrollEvent event, Emitter<FilePageState> emit) {
    debugPrint(
        "_fileListScroll _currentFile->${_currentFile?.name} position->${event.position}");
    _currentFile?.position = event.position;
    state.fileListPosition = event.position;
  }

  OpenDirResult? get _currentFile {
    final paths = state.paths;
    return paths.isNotEmpty ? paths.last : null;
  }

  Future<void> _refreshData(
      RefreshDataEvent event, Emitter<FilePageState> emit) async {
    await _refresh(emit, isShowDialog: event.completer == null);
    event.completer?.complete();
  }

  Future<void> _forward(ForwardEvent event, Emitter<FilePageState> emit) async {
    final fileName = state.children[event.index].name;

    if (fileName == null || fileName.isEmpty) return;

    final newPath = _getWholePathList(fileName: fileName);

    final openFile = await _openDir(newPath);

    if (openFile == null) return;

    emit(state.clone()
      ..paths = [...state.paths, openFile]
      ..children = openFile.children ?? []);
  }

  FutureOr<void> _downloadFile(
      DownloadFileEvent event, Emitter<FilePageState> emit) async {
    _platformAdapter.webOpen(
        url: await _getDownloadUrl(state.children[event.index].name));
  }

  Future<void> _uploadFile(
      UploadFileEvent uploadFileEvent, Emitter<FilePageState> emit) async {
    await _platformAdapter.uploadFile(
        isDir: uploadFileEvent.dir,
        getFileParentPath: ({String? dir}) async {
          if (uploadFileEvent.dir && dir != null && dir.isNotEmpty) {
            await _createDir(CreateDirEvent(dir), emit);
            return "${_getWholePathStr()},$dir";
          }
          return _getWholePathStr();
        });

    _refresh(emit);
  }

  Future<String> _getDownloadUrl(String? fileName) async {
    final sp = await SharedPreferences.getInstance();

    final filePathsJson = json.encode(_getWholePathList(fileName: fileName));

    final filePaths =
        const Base64Encoder.urlSafe().convert(utf8.encode(filePathsJson));

    return "${NetworkConfig.urlBase}${NetworkConfig.apiDownloadFile}?token=${sp.getString(SpConfig.keyToken)}&filePaths=$filePaths";
  }

  //获取完整路径数组
  List<String> _getWholePathList(
      {List<OpenDirResult>? paths, String? fileName}) {
    final pathList =
        (paths ?? state.paths).map((e) => e.name).whereNotNull().toList();

    if (fileName != null) pathList.add(fileName);

    return pathList;
  }

  //获取完整路径字符串，逗号分隔
  String _getWholePathStr({String? fileName}) {
    final sb = StringBuffer()
      ..writeAll(_getWholePathList(fileName: fileName), ",");
    return sb.toString();
  }

  Future<void> _playVideo(
      PlayVideoEvent event, Emitter<FilePageState> emit) async {
    final videoUrl = await _getDownloadUrl(state.children[event.index].name);
    // js.context.callMethod(
    //     'openVideoUrlWithSysProgram', [videoUrl]);

    switch (event.type) {
      case PlayVideoEvent.typePotPlayer:
        _platformAdapter.webOpen(url: "potplayer://$videoUrl");
        break;
    }
  }

  //获取数据大小显示值
  String _getDisplaySize(double byte) {
    if (byte < 1024) {
      return "$byte B";
    } else if (byte < 1024 * 1024) {
      return "${(byte / 1024).round()} KB";
    } else if (byte < 1024 * 1024 * 1024) {
      return "${(byte / (1024 * 1024)).toStringAsFixed(1)} MB";
    } else {
      return "${(byte / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    }
  }

  void _showProgressDialogSuccess(
          ShowProgressDialogSuccessEvent event, Emitter<FilePageState> emit) =>
      _progressDialogCompleter?.complete();

  void _showWaitServerDialogSuccess(ShowWaitServerDialogSuccessEvent event,
          Emitter<FilePageState> emit) =>
      _waitServerDialogCompleter?.complete();

  void _switchView(SwitchViewEvent event, Emitter<FilePageState> emit) {
    emit(state.clone()..isGridView = !state.isGridView);
  }

  FutureOr<void> _updateTasks(
      UpdateTasksEvent event, Emitter<FilePageState> emit) {
    emit(state.clone()..updateTasks = event.updateTasks);
  }

  Future<FutureOr<void>> _rename(
      RenameEvent event, Emitter<FilePageState> emit) async {
    final paths = _getWholePathList(fileName: state.children[event.index].name);
    final newPaths = _getWholePathList(fileName: event.newName);

    final result = await DioManager().doPost(
        api: NetworkConfig.apiRenameFile,
        data: {"paths": paths, "newPaths": newPaths},
        transformer: (Map<String, dynamic> json) =>
            RenameFileEntity.fromJson(json),
        context: _context);

    if (result != null) {
      Util.showDefaultToast("修改成功");
    }

    add(InitEvent());
  }

  FutureOr<void> _showDirChooseDialog(
      ShowDirChooseDialogEvent event, Emitter<FilePageState> emit) {
    final paths = state.paths;

    if (paths.isEmpty) return null;

    emit(state.clone()..dirChoosePaths = [paths.first]);
  }

  Future<void> _moveFileEvent(
      MoveFileEvent event, Emitter<FilePageState> emit) async {
    var fileName = state.children[event.index].name;
    final paths = _getWholePathList(fileName: fileName);
    final newPaths =
        _getWholePathList(paths: state.dirChoosePaths, fileName: fileName);

    final result = await DioManager().doPost(
        api: NetworkConfig.apiRenameFile,
        data: {"paths": paths, "newPaths": newPaths},
        transformer: (Map<String, dynamic> json) =>
            RenameFileEntity.fromJson(json),
        context: _context);

    if (result != null) {
      Util.showDefaultToast("修改成功");
    }

    await _refresh(emit);
  }

  Future<void> _dirChooseForward(
      DirChooseForwardEvent event, Emitter<FilePageState> emit) async {
    final paths = state.dirChoosePaths;

    if (paths.isEmpty) return;

    final fileName = paths.last.children?[event.index].name;

    if (fileName == null || fileName.isEmpty) return;

    final openDirResult = await _openDir(_getWholePathList(fileName: fileName));

    if (openDirResult == null) return;

    final newPath = paths.toList();

    newPath.add(openDirResult);

    emit(state.clone()..dirChoosePaths = newPath);
  }

  FutureOr<void> _dirChooseBackward(
      DirChooseBackwardEvent event, Emitter<FilePageState> emit) {
    final paths = state.dirChoosePaths;
    if (paths.length > 1) {
      emit(state.clone()..dirChoosePaths = (paths.toList()..removeLast()));
    }
  }

  FutureOr<void> _selectEvent(SelectEvent event, Emitter<FilePageState> emit) {
    final newChildren = state.children.toList();
    final child = newChildren[event.index];
    child.isSelected = !child.isSelected;
    emit(state.clone()..children = newChildren);
    _emitSelectModeState(emit);
  }

  FutureOr<void> _closeSelectModeEvent(
      CloseSelectModeEvent event, Emitter<FilePageState> emit) {
    final newChildren = state.children.toList()
      ..forEach((element) {
        element.isSelected = false;
      });
    emit(state.clone()..children = newChildren);
    _emitSelectModeState(emit);
  }

  _emitSelectModeState(Emitter<FilePageState> emit) {
    emit(state.clone()
      ..selectMode = state.children.any((element) => element.isSelected));
  }

  FutureOr<void> _openFile(
      OpenFileEvent event, Emitter<FilePageState> emit) async {
    final name = state.children[event.index].name;
    if (name == null || name.isEmpty) return;
    final mimeType = lookupMimeType(name);
    final url = await _getDownloadUrl(name);
    const channel = MethodChannel("channel");
    await channel.invokeMethod("playVideo", {"url": url, "mimeType": mimeType});

    // Navigator.of(event.context)
    //     .pushNamed("/video", arguments: VideoPageArgs(url));
  }
}
