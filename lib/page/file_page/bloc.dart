import 'dart:async';
import 'dart:convert';
import 'dart:js';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/config.dart';
import '../../manager/dio_manager.dart';
import '../../model/entity/create_dir_entity.dart';
import '../../model/entity/delete_file_entity.dart';
import '../../model/entity/list_file_entity.dart';
import 'event.dart';
import 'state.dart';
import 'dart:html' as html;

class FilePageBloc extends Bloc<FilePageEvent, FilePageState> {
  final BuildContext _context;

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

  Future<void> _uploadFile(
      UploadFileEvent event, Emitter<FilePageState> emit) async {
    //上传完成通知器
    final completer = Completer<void>();

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
        emit.call(state.clone()..showWaitServerDialog = false);
        add(InitEvent());

        completer.complete();
      });

      request.upload.onLoadEnd.listen((event) {
        print("上传完成");

        emit.call(state.clone()..showUploadProgressDialog = false);

        emit.call(state.clone()..showWaitServerDialog = true);
      });

      for (final element in files) {
        formData.appendBlob("file", element, element.name);
      }
      request.send(formData);
    });

    await completer.future;
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
}
