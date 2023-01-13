import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:bloc/bloc.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/config.dart';
import '../../manager/dio_manager.dart';
import '../../model/entity/create_dir_entity.dart';
import '../../model/entity/delete_file_entity.dart';
import '../../model/entity/list_file_entity.dart';
import 'event.dart';
import 'state.dart';

class FilePageBloc extends Bloc<FilePageEvent, FilePageState> {
  final BuildContext _context;
  WebSocketChannel? webSocketChannel;
  Completer<void>? progressDialogCompleter;
  Completer<void>? waitServerDialogCompleter;

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
    on<UpdateTasksEvent>(_updateTasksEvent);

    SharedPreferences.getInstance().then((sp) {
      final token = sp.getString(SpConfig.keyToken);

      final channel = WebSocketChannel.connect(Uri.parse(
          "${NetworkConfig.wsUrlBase}${NetworkConfig.apiWsUploadTasks}?token=$token"));

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
      });

      channel.sink.add("hello from flutter");

      webSocketChannel = channel;
    });
  }

  @override
  Future<void> close() async {
    super.close();
    webSocketChannel?.sink.close();
  }

  Future<void> _init(InitEvent event, Emitter<FilePageState> emit) async {
    await _refresh(emit);
  }

  FutureOr<void> _back(BackEvent event, Emitter<FilePageState> emit) {
    final paths = state.paths.toList();
    if (paths.length > 1) {
      paths.removeAt(paths.length - 1);
      _refreshList(paths, emit);
    }
  }

  FutureOr<void> _createDir(
      CreateDirEvent event, Emitter<FilePageState> emit) async {
    final name = event.name;

    final paths = _getWholePathList(fileName: name);

    final createDirEntity = await DioManager().doPost(
        api: NetworkConfig.apiCreateDir,
        data: {"paths": paths},
        transformer: (Map<String, dynamic> json) =>
            CreateDirEntity.fromJson(json),
        context: _context);

    if (createDirEntity == null) return;

    await _refresh(emit);
  }

  FutureOr<void> _deleteFile(
      DeleteFileEvent event, Emitter<FilePageState> emit) async {
    final name = event.name;

    final paths = _getWholePathList(fileName: name);

    final deleteFileResult = await DioManager().doPost(
        api: NetworkConfig.apiDeleteFile,
        data: {"paths": paths},
        transformer: (json) => DeleteFileEntity.fromJson(json),
        context: _context);

    if (deleteFileResult == null) return;

    await _refresh(emit);
  }

  Future<void> _refresh(Emitter<FilePageState> emit) async {
    final listFile = await DioManager()
        .doPost(
            api: NetworkConfig.apiListFile,
            transformer: (json) => ListFileEntity.fromJson(json),
            context: _context)
        .then((value) => value?.result);

    if (listFile == null) return;

    final _currentPaths = state.paths.toList();

    final files = [listFile];

    for (int deep = 0; deep < _currentPaths.length; deep++) {
      var replace = false;
      for (var element in files) {
        print(
            "_refresh 第${deep}层->${_currentPaths[deep].name}  对比 ${element.name}");

        final path = _currentPaths[deep];

        if (element.name == path.name) {
          _currentPaths.replaceRange(
              deep, deep + 1, [element..position = path.position]);

          // print("_refresh 替换->${_paths[deep].name}");

          replace = true;
        }
      }
      //如果本层没有匹配的目录，则回退到上一层
      if (!replace) {
        _currentPaths.sublist(0, deep);
        break;
      }

      final last = files.toList();
      files.clear();
      for (var element in last) {
        element.children?.forEach((element) {
          files.add(element);
        });
      }

      print("_refresh 第${deep}层->files：${files.length}");

      //如果下一层已经没有目录了，那路径将止步于此
      if (files.isEmpty) {
        _currentPaths.sublist(0, deep + 1);
        break;
      }
    }

    if (_currentPaths.isEmpty) _currentPaths.add(listFile);

    void sort(ListFileResult path) {
      final children = path.children;
      children?.sort((ListFileResult a, ListFileResult b) {
        if (a.isDir == b.isDir) {
          return (b.size ?? 0).compareTo(a.size ?? 0);
        }
        if (a.isDir) {
          return -1;
        } else {
          return 1;
        }
      });
      children?.forEach((child) {
        sort(child);
      });
    }

    //排序-文件夹排前面-size大的排前面
    for (final path in _currentPaths) {
      sort(path);
    }

    final sp = await SharedPreferences.getInstance();

    void assemblePreviewImgUrl(ListFileResult path) {
      final previewImg = path.previewImg;
      if (previewImg != null) {
        path.previewImgUrl =
            "${NetworkConfig.urlBase}${path.previewImg}&token=${sp.getString(SpConfig.keyToken)}";
        debugPrint("previewImgUrl -> ${path.previewImgUrl}");
      }

      path.children?.forEach((element) {
        assemblePreviewImgUrl(element);
      });
    }

    //previewImg生成的完整url
    for (final path in _currentPaths) {
      assemblePreviewImgUrl(path);
    }

    _refreshList(_currentPaths, emit);
  }

  void _fileListScroll(FileListScrollEvent event, Emitter<FilePageState> emit) {
    debugPrint(
        "_fileListScroll _currentFile->${_currentFile?.name} position->${event.position}");
    _currentFile?.position = event.position;
    state.fileListPosition = event.position;
  }

  ListFileResult? get _currentFile {
    final paths = state.paths;
    return paths.isNotEmpty ? paths.last : null;
  }

  Future<void> _refreshData(
      RefreshDataEvent event, Emitter<FilePageState> emit) async {
    await _refresh(emit);
  }

  void _forward(ForwardEvent event, Emitter<FilePageState> emit) {
    final newPath = state.paths.toList();
    newPath.add(state.children[event.index]);

    _refreshList(newPath, emit);
  }

  void _refreshList(List<ListFileResult> paths, Emitter<FilePageState> emit) {
    final children = paths.last.children ?? [];

    for (final file in children) {
      final size = file.size;
      file.displaySize = size != null ? _getDisplaySize(size.toDouble()) : "";
    }

    emit(state.clone()
      ..paths = paths
      ..children = children);

    debugPrint("_currentFile->${_currentFile?.name}");

    emit(state.clone()..fileListPosition = _currentFile?.position ?? 0);
  }

  FutureOr<void> _downloadFile(
      DownloadFileEvent event, Emitter<FilePageState> emit) async {
    html.window
        .open(await _getDownloadUrl(state.children[event.index].name), "_self");
  }

  Future<void>? _uploadFileComplete;

  Future<void> _uploadFile(
      UploadFileEvent event, Emitter<FilePageState> emit) async {
    // await _uploadOldWay(emit);

    final currentUploadCompleter = Completer();

    if (_uploadFileComplete != null) {
      _uploadFileComplete =
          _uploadFileComplete?.then((value) => currentUploadCompleter.future);
    } else {
      _uploadFileComplete = Future.wait([currentUploadCompleter.future]);
    }

    final token =
        (await SharedPreferences.getInstance()).getString(SpConfig.keyToken);
    final filePath = _getWholePathStr();

    final element = html.InputElement(type: 'file');
    // final element = html.FileUploadInputElement();
    element.multiple = true;
    element.draggable = false;
    // element.directory = true;
    element.click();

    element.onChange.listen((event) {
      final files = element.files;
      if (files == null || files.isEmpty == true) {
        return;
      }

      int loadEndFlag = 0;

      for (final file in files) {
        final formData = html.FormData();
        final request = html.HttpRequest();

        request.onLoadEnd.listen((event) {
          // final resp = request.responseText;
          //
          // if(resp !=null) {
          //   final result = CommonEntity.fromJson(json.decode(resp));
          //
          //   DioManager().defaultHandle(result);
          // }

          if (++loadEndFlag == files.length) currentUploadCompleter.complete();
        });

        request.open("POST",
            "${NetworkConfig.urlBase}${NetworkConfig.apiUploadFile}?token=$token&path=$filePath");

        formData.appendBlob("file", file, file.name);
        request.send(formData);
      }
    });

    await currentUploadCompleter.future;

    Future? uploadFileComplete;

    while (uploadFileComplete != _uploadFileComplete) { //如果第二次进入了while，证明_uploadFileComplete被更新了，也就是还有新的任务要等待
      uploadFileComplete = _uploadFileComplete;
      await uploadFileComplete;
    }

    add(InitEvent());
  }

  Future<void> _uploadOldWay(Emitter<FilePageState> emit) async {
    //上传完成通知器
    final completer = Completer<void>();

    progressDialogCompleter = Completer<void>();
    waitServerDialogCompleter = Completer<void>();

    final element = html.FileUploadInputElement();
    element.multiple = true;
    element.draggable = false;
    element.click();

    element.onChange.listen((event) async {
      final files = element.files;
      if (files == null || files.isEmpty == true) {
        return;
      }

      final formData = html.FormData();
      final token =
          (await SharedPreferences.getInstance()).getString(SpConfig.keyToken);
      final filePath = _getWholePathStr();
      final request = html.HttpRequest();

      double progress = 0;
      double speed = 0; //上传速率
      html.ProgressEvent? lastEvent; //上次的上传事件，用来计算上传速率

      //弹出进度弹框
      emit.call(state.clone()
        ..showUploadProgressDialog = true
        ..uploadProgress = 0);

      request.open("POST",
          "${NetworkConfig.urlBase}${NetworkConfig.apiUploadFile}?token=$token&path=$filePath");

      request.upload.onProgress.listen((event) {
        final loaded = event.loaded ?? 0;
        final total = event.total ?? 0;
        final timeStamp = event.timeStamp ?? 0;

        progress = total == 0 ? progress : loaded / total;

        final _lastEvent = lastEvent;
        if (_lastEvent == null) {
          lastEvent = event;
        } else {
          final lastLoaded = _lastEvent.loaded ?? 0;
          final lastTimeStamp = _lastEvent.timeStamp ?? 0;

          speed = (loaded - lastLoaded) / ((timeStamp - lastTimeStamp) / 1000);

          emit.call(state.clone()
            ..uploadProgress = progress
            ..speed = speed
            ..displaySpeed = _getDisplaySize(speed));
        }
      });

      request.onLoadEnd.listen((event) async {
        print("request.onLoadEnd");

        await waitServerDialogCompleter?.future;

        emit.call(state.clone()..showWaitServerDialog = false);

        completer.complete();
      });

      request.upload.onLoadEnd.listen((event) async {
        print("上传完成");

        await progressDialogCompleter?.future;

        emit.call(state.clone()..showUploadProgressDialog = false);

        emit.call(state.clone()..showWaitServerDialog = true);
      });

      for (final element in files) {
        formData.appendBlob("file", element, element.name);
      }
      request.send(formData);
    });

    await completer.future;

    add(InitEvent());

    progressDialogCompleter = null;
    waitServerDialogCompleter = null;
  }

  Future<String> _getDownloadUrl(String? fileName) async {
    final sp = await SharedPreferences.getInstance();

    final filePaths = const Base64Encoder.urlSafe()
        .convert(utf8.encode(_getWholePathStr(fileName: fileName)));

    return "${NetworkConfig.urlBase}${NetworkConfig.apiDownloadFile}?token=${sp.getString(SpConfig.keyToken)}&filePaths=$filePaths";
  }

  //获取完整路径数组
  List<String> _getWholePathList({String? fileName}) {
    final pathList = state.paths.map((e) => e.name).toList();

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
        html.window.open("potplayer://$videoUrl", "_self");
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
      progressDialogCompleter?.complete();

  void _showWaitServerDialogSuccess(ShowWaitServerDialogSuccessEvent event,
          Emitter<FilePageState> emit) =>
      waitServerDialogCompleter?.complete();

  void _switchView(SwitchViewEvent event, Emitter<FilePageState> emit) {
    emit(state.clone()..isGridView = !state.isGridView);
  }

  FutureOr<void> _updateTasksEvent(
      UpdateTasksEvent event, Emitter<FilePageState> emit) {
    emit(state.clone()..updateTasks = event.updateTasks);
  }
}
