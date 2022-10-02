import 'dart:async';
import 'dart:html' as html;
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  final _scrollController = ScrollController();

  late final FilePageBloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = FilePageBloc(context);

    // 屏蔽浏览器默认的右键点击事件
    html.window.document.onContextMenu.listen((evt) => evt.preventDefault());

    _scrollController.addListener(() {
      _bloc.add(FileListScrollEvent(_scrollController.position.pixels));
    });

    _bloc.add(InitEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _bloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<FilePageBloc, FilePageState>(
            listener: (BuildContext context, FilePageState state) async {
              await _nextFrame();
              final jumpTo = min(_scrollController.position.maxScrollExtent,
                  state.fileListPosition);

              debugPrint(
                  "jumpTo->${jumpTo}  max${_scrollController.position.maxScrollExtent}");

              _scrollController.jumpTo(jumpTo);
            },
            listenWhen: (FilePageState previous, FilePageState current) =>
                previous.fileListPosition != current.fileListPosition,
          ),
          BlocListener<FilePageBloc, FilePageState>(
            listener: (BuildContext _, FilePageState state) {
              debugPrint("showWaitServerDialog:${state.showWaitServerDialog}");

              if (state.showWaitServerDialog) {
                showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      _bloc.add(ShowWaitServerDialogSuccessEvent());
                      debugPrint("弹出${dialogContext.hashCode}");
                      return BlocProvider.value(
                        value: _bloc,
                        child: Material(
                          child: Center(
                            child: Container(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(25, 15, 25, 15),
                                  child: Column(
                                    children: const [
                                      CircularProgressIndicator(),
                                      Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5)),
                                      Text("正在等待服务器")
                                    ],
                                    mainAxisSize: MainAxisSize.min,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8))),
                          ),
                          color: Colors.transparent,
                        ),
                      );
                    });
              } else {
                Navigator.of(context).pop();
              }
            },
            listenWhen: (FilePageState previous, FilePageState current) =>
                previous.showWaitServerDialog != current.showWaitServerDialog,
          ),
          BlocListener<FilePageBloc, FilePageState>(
            listener: (BuildContext context, FilePageState state) async {
              debugPrint(
                  "showUploadProgressDialog->${state.showUploadProgressDialog}");

              if (state.showUploadProgressDialog) {
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (BuildContext dialogContext) {
                      _bloc.add(ShowProgressDialogSuccessEvent());
                      return BlocProvider.value(
                        value: _bloc,
                        child: Material(
                          child: Center(
                            child: Container(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(25, 15, 25, 15),
                                  child: Column(
                                    children: [
                                      BlocBuilder<FilePageBloc, FilePageState>(
                                        builder: (BuildContext context,
                                            FilePageState state) {
                                          return CircularProgressIndicator(
                                            value: state.uploadProgress,
                                          );
                                        },
                                        buildWhen: (FilePageState previous,
                                                FilePageState current) =>
                                            previous.uploadProgress !=
                                            current.uploadProgress,
                                      ),
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5)),
                                      BlocBuilder<FilePageBloc, FilePageState>(
                                        builder: (BuildContext context,
                                            FilePageState state) {
                                          return Text(
                                            "${(state.uploadProgress * 100).toInt().toString()}%",
                                          );
                                        },
                                        buildWhen: (FilePageState previous,
                                                FilePageState current) =>
                                            previous.uploadProgress !=
                                            current.uploadProgress,
                                      ),
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5)),
                                      BlocBuilder<FilePageBloc, FilePageState>(
                                        builder: (BuildContext context,
                                            FilePageState state) {
                                          return Text(state.displaySpeed);
                                        },
                                        buildWhen: (FilePageState previous,
                                                FilePageState current) =>
                                            previous.displaySpeed !=
                                            current.displaySpeed,
                                      ),
                                    ],
                                    mainAxisSize: MainAxisSize.min,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8))),
                          ),
                          color: Colors.transparent,
                        ),
                      );
                    });
              } else {
                Navigator.of(context).pop();
              }
            },
            listenWhen: (FilePageState previous, FilePageState current) =>
                previous.showUploadProgressDialog !=
                current.showUploadProgressDialog,
          )
        ],
        child: WillPopScope(
          child: Scaffold(
            appBar: AppBar(
              title: const Text("文件"),
              automaticallyImplyLeading: false,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // shrinkWrap: true,
              // mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(5, 7, 0, 15),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                            onPressed: () => _bloc.add(UploadFileEvent()),
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)))),
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: const Text("上传文件")),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        ElevatedButton.icon(
                            onPressed: () async {
                              final controller = TextEditingController();

                              final confirm = await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                        title: const Text("请输入文件夹名字"),
                                        content: TextField(
                                          controller: controller,
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text("确定")),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text("取消"))
                                        ],
                                      ));

                              final name = controller.text;

                              if (!confirm || name.isEmpty) {
                                return;
                              }

                              _bloc.add(CreateDirEvent(name));
                            },
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)))),
                            icon: const Icon(Icons.create_new_folder),
                            label: const Text("新建文件夹")),
                        Expanded(
                            child: Container(
                          height: 0,
                        )),
                        BlocBuilder<FilePageBloc, FilePageState>(
                          buildWhen:
                              (FilePageState previous, FilePageState current) =>
                                  previous.isGridView != current.isGridView,
                          builder: (BuildContext context,
                                  FilePageState state) =>
                              IconButton(
                                  onPressed: () => _bloc.add(SwitchViewEvent()),
                                  icon: Icon(
                                    state.isGridView
                                        ? Icons.list
                                        : Icons.grid_view,
                                    color: Colors.black45,
                                  )),
                        ),
                        IconButton(
                            onPressed: () => _bloc.add(RefreshDataEvent()),
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.black45,
                            ))
                      ],
                    )),
                SizedBox(
                    height: 30,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: buildPathList(),
                      ),
                    )),
                _getDivider(),
                Flexible(
                  child: buildChildrenList(),
                ),
              ],
            ),
          ),
          onWillPop: () async {
            _bloc.add(BackEvent());
            return false;
          },
        ),
      ),
    );
  }

  Widget buildChildrenList() => BlocBuilder<FilePageBloc, FilePageState>(
        builder: (BuildContext context, FilePageState state) {
          final children = state.children;

          return BlocBuilder<FilePageBloc, FilePageState>(
            buildWhen: (FilePageState previous, FilePageState current) =>
                previous.isGridView != current.isGridView,
            builder: (BuildContext context, FilePageState state) => state
                    .isGridView
                ? LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                    debugPrint(
                        "constraints.maxWidth => ${constraints.maxWidth}  屏幕 => ${html.window.screen?.width}");

                    //假设窗口最大时横向为15个item
                    final oneItemWidth = (html.window.screen?.width ?? 0) / 15;

                    debugPrint("oneItemWidth -> ${oneItemWidth}");

                    final crossAxisCount =
                        max(constraints.maxWidth ~/ oneItemWidth, 1);

                    return GridView.builder(
                        controller: _scrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: 1 / 1.5,
                            crossAxisCount: crossAxisCount),
                        itemCount: children.length,
                        itemBuilder: (BuildContext context, int index) {
                          final file = children[index];
                          final previewImg = file.previewImg;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onSecondaryTapUp: (TapUpDetails details) async =>
                                await onSecondaryTapUp(
                                    file, context, details, index),
                            onTap: () => onTap(file, index),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  FractionallySizedBox(
                                    widthFactor: 1,
                                    child: AspectRatio(
                                        aspectRatio: 1 / 1,
                                        child: previewImg != null
                                            ? Image.network(
                                                "${file.previewImgUrl}",
                                                fit: BoxFit.contain,
                                              )
                                            : Icon(
                                                file.isDir
                                                    ? Icons.folder
                                                    : Icons
                                                        .description_outlined,
                                                color: file.isDir
                                                    ? Colors.orangeAccent
                                                    : Colors.grey,
                                              )),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Expanded(
                                      child: AutoSizeText(
                                    file.name,
                                  )),
                                ],
                              ),
                            ),
                          );
                        });
                  })
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    separatorBuilder: (BuildContext context, int index) =>
                        _getDivider(),
                    itemCount: children.length,
                    itemBuilder: (BuildContext context, int index) {
                      final file = children[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
                          child: Row(
                            children: [
                              Icon(
                                file.isDir
                                    ? Icons.folder
                                    : Icons.description_outlined,
                                color: file.isDir
                                    ? Colors.orangeAccent
                                    : Colors.grey,
                                size: 29,
                              ),
                              const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3)),
                              Text(file.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                  )),
                              const Spacer(),
                              Text(file.displaySize),
                            ],
                            mainAxisSize: MainAxisSize.max,
                          ),
                        ),
                        onSecondaryTapUp: (TapUpDetails details) async =>
                            await onSecondaryTapUp(
                                file, context, details, index),
                        onTap: () => onTap(file, index),
                      );
                    },
                  ),
          );
        },
        buildWhen: (FilePageState previous, FilePageState current) =>
            previous.children != current.children ||
            previous.children.length != current.children.length,
      );

  void onTap(ListFileResult file, int index) {
    if (file.isDir) {
      _bloc.add(ForwardEvent(index));
    }
  }

  Future<void> onSecondaryTapUp(ListFileResult file, BuildContext context,
      TapUpDetails details, int index) async {
    final mimeType = lookupMimeType(file.name);

    print("onSecondaryTapUp: lookupMimeType->${lookupMimeType(file.name)}");

    // lookupMimeType(file.name);

    const idDelete = 0;
    const idDownload = 1;
    const idPlayVideo = 2;

    final data = {idDelete: "删除"};

    if (!file.isDir) {
      data.addAll({idDownload: "下载"});
      if (mimeType?.startsWith("video") == true) {
        data.addAll({idPlayVideo: "使用potPlayer播放"});
      }
    }

    final overlay =
        Overlay.of(context)?.context.findRenderObject() as RenderBox;
    int? id = await showMenu<int>(
        context: context,
        items: data.entries
            .map((e) => PopupMenuItem(
                  child: Text(e.value),
                  value: e.key,
                ))
            .toList(),
        position: RelativeRect.fromRect(
            Rect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy,
                details.globalPosition.dx, details.globalPosition.dy),
            Offset.zero & overlay.size));

    switch (id) {
      case idDelete:
        final delete = await showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: const Text("警告"),
                  content: Text("确认删除${file.name}吗"),
                  actions: [
                    TextButton(
                      child: const Text("取消"),
                      onPressed: () => Navigator.of(context).pop(false), //关闭对话框
                    ),
                    TextButton(
                      child: const Text("删除"),
                      onPressed: () {
                        // ... 执行删除操作
                        Navigator.of(context).pop(true); //关闭对话框
                      },
                    ),
                  ],
                ));

        if (delete) {
          _bloc.add(DeleteFileEvent(file.name));
        }
        break;
      case idDownload:
        _bloc.add(DownloadFileEvent(index));
        break;
      case idPlayVideo:
        _bloc.add(PlayVideoEvent(PlayVideoEvent.typePotPlayer, index));
        break;
    }
  }

  Widget buildPathList() => BlocBuilder<FilePageBloc, FilePageState>(
        builder: (BuildContext context, FilePageState state) {
          var paths = state.paths;
          return ListView.separated(
              separatorBuilder: (BuildContext context, int index) => Center(
                    child: Text(
                      "  >  ",
                      style:
                          TextStyle(color: Theme.of(context).primaryColorLight),
                    ),
                  ),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: paths.length,
              itemBuilder: (BuildContext context, int index) {
                return Center(
                    child: Text(paths[index].name,
                        style: TextStyle(
                          color: index == paths.length - 1
                              ? Theme.of(context).unselectedWidgetColor
                              : Theme.of(context).primaryColorDark,
                        )));
              });
        },
        buildWhen: (FilePageState previous, FilePageState current) =>
            previous.paths != current.paths ||
            previous.paths.length != current.paths.length,
      );

  Widget _getDivider() => const Divider(
        height: 5,
      );

  Future<void> _nextFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer.complete();
    });
    await completer.future;
  }
}
