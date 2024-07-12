import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/model/entity/open_dir_entity.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';
import 'package:cloud_driver/page/login/login_page.dart';
import 'package:cloud_driver/route/PopupWindowRoute.dart';
import 'package:cloud_driver/util/util.dart';
import 'package:cloud_driver/widget/ExpandableFab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mime/mime.dart';

import 'package:cloud_driver/page/file/base_page_state.dart';
import 'package:cloud_driver/page/file/file_page_bloc.dart';
import 'package:cloud_driver/page/file/file_page_event.dart';
import 'package:cloud_driver/model/state/file_page_state.dart';
import 'package:url_launcher/url_launcher.dart';

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FilePageState();
}

class _FilePageState extends BasePageState {
  final _scrollController = ScrollController();
  final _taskButtonKey = GlobalKey();
  final _uploadButtonKey = GlobalKey();
  final _platformAdapter = PlatformAdapter();

  @override
  void initState() {
    super.initState();
    // 屏蔽浏览器默认的右键点击事件
    _platformAdapter.webBlocRightClick();

    _scrollController.addListener(() {
      bloc.add(FileListScrollEvent(_scrollController.position.pixels));
    });

    bloc.add(InitEvent());
  }

  @override
  Widget build(BuildContext context) {
    final uploadMenuController = MenuController();

    return BlocProvider(
      create: (_) => bloc,
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
                      bloc.add(ShowWaitServerDialogSuccessEvent());
                      debugPrint("弹出${dialogContext.hashCode}");
                      return BlocProvider.value(
                        value: bloc,
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
                // previous.showWaitServerDialog != current.showWaitServerDialog,
                false,
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
                      bloc.add(ShowProgressDialogSuccessEvent());
                      return BlocProvider.value(
                        value: bloc,
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
                // previous.showUploadProgressDialog !=
                // current.showUploadProgressDialog,
                false,
          ),
          BlocListener<FilePageBloc, FilePageState>(
            listenWhen: (previous, current) {
              return current.openVideoPageEvent != null;
            },
            listener: (BuildContext context, FilePageState state) {
              final event = state.openVideoPageEvent;
              if (event == null) return;
              launchUrl(Uri.parse(event.url));
            },
          ),
        ],
        child: PopScope(
          child: Scaffold(
            appBar: AppBar(
              title: const Text("文件"),
              automaticallyImplyLeading: false,
              actions: [_buildLogoutAction()],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(5, 7, 0, 15),
                    child: Row(
                      children: [
                        MenuAnchor(
                          child: ElevatedButton.icon(
                              key: _uploadButtonKey,
                              onPressed: () {
                                if (uploadMenuController.isOpen) {
                                  uploadMenuController.close();
                                } else {
                                  uploadMenuController.open();
                                }
                              },
                              style: _getButtonStyle(),
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: const Text("上传")),
                          controller: uploadMenuController,
                          menuChildren: [
                            MenuItemButton(
                              style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                      EdgeInsets.zero)),
                              onPressed: () => bloc.add(UploadFileEvent(false)),
                              child: Builder(builder: (BuildContext context) {
                                final box = _uploadButtonKey.currentContext
                                    ?.findRenderObject() as RenderBox;
                                return Container(
                                  alignment: Alignment.center,
                                  width: box.size.width,
                                  child: const Text("文件"),
                                );
                              }),
                            ),
                            MenuItemButton(
                              style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                      EdgeInsets.zero)),
                              onPressed: () => bloc.add(UploadFileEvent(true)),
                              child: Builder(builder: (BuildContext context) {
                                final box = _uploadButtonKey.currentContext
                                    ?.findRenderObject() as RenderBox;
                                return Container(
                                  alignment: Alignment.center,
                                  width: box.size.width,
                                  child: const Text("文件夹"),
                                );
                              }),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 10.w,
                        ),
                        ElevatedButton.icon(
                            onPressed: onPressCreateDir,
                            style: _getButtonStyle(),
                            icon: const Icon(Icons.create_new_folder),
                            label: const Text("新建文件夹")),
                        const Spacer(),
                        IconButton(
                            key: _taskButtonKey,
                            onPressed: () {
                              if (bloc.state.updateTasks.isEmpty) {
                                Util.showDefaultToast("没有任务");
                                return;
                              }

                              final renderOjb = _taskButtonKey.currentContext
                                  ?.findRenderObject();

                              if (renderOjb is RenderBox) {
                                final offset =
                                    renderOjb.localToGlobal(Offset.zero);

                                final right =
                                    MediaQuery.of(context).size.width -
                                        offset.dx -
                                        renderOjb.size.width;
                                final top = offset.dy + renderOjb.size.height;

                                Navigator.push(
                                    context,
                                    PopupWindowRoute((BuildContext
                                            routeContext) =>
                                        PopupWindow(
                                          BlocProvider.value(
                                            value: bloc,
                                            child: BlocBuilder<FilePageBloc,
                                                    FilePageState>(
                                                buildWhen:
                                                    (FilePageState previous,
                                                            FilePageState
                                                                current) =>
                                                        previous.updateTasks !=
                                                        current.updateTasks,
                                                builder: (BuildContext context,
                                                    FilePageState state) {
                                                  final tasks =
                                                      state.updateTasks;

                                                  return Card(
                                                    child: SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            3,
                                                        child: tasks.isNotEmpty
                                                            ? _buildTaskList(
                                                                state
                                                                    .updateTasks)
                                                            : const Center(
                                                                child: Padding(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          vertical:
                                                                              5),
                                                                  child: Text(
                                                                      "没有进行中的任务"),
                                                                ),
                                                              )),
                                                  );
                                                }),
                                          ),
                                          alignment:
                                              AlignmentDirectional.topEnd,
                                          right: right,
                                          top: top,
                                        )));
                              }
                            },
                            icon: const Icon(
                              Icons.backup,
                              color: Colors.black45,
                            )),
                        BlocBuilder<FilePageBloc, FilePageState>(
                          buildWhen:
                              (FilePageState previous, FilePageState current) =>
                                  previous.isGridView != current.isGridView,
                          builder: (BuildContext context,
                                  FilePageState state) =>
                              IconButton(
                                  onPressed: () => bloc.add(SwitchViewEvent()),
                                  icon: Icon(
                                    state.isGridView
                                        ? Icons.list
                                        : Icons.grid_view,
                                    color: Colors.black45,
                                  )),
                        ),
                        IconButton(
                            onPressed: () => bloc.add(RefreshDataEvent(null)),
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.black45,
                            ))
                      ],
                    )),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: BlocBuilder<FilePageBloc, FilePageState>(
                    builder: (BuildContext context, FilePageState state) {
                      var paths = state.paths;
                      return _buildPathList(paths);
                    },
                    buildWhen:
                        (FilePageState previous, FilePageState current) =>
                            previous.paths != current.paths,
                  ),
                ),
                _getDivider(),
                Expanded(
                  child: RefreshIndicator(
                    child: _buildChildrenList(),
                    onRefresh: () async {
                      final completer = Completer<void>();
                      bloc.add(RefreshDataEvent(completer));
                      await completer.future;
                    },
                  ),
                ),
              ],
            ),
          ),
          canPop: false,
          onPopInvoked: (didPop) async {
            bloc.add(BackEvent());
          },
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    return ButtonStyle(
        shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  ///当前目录的文件列表
  Widget _buildChildrenList() => BlocBuilder<FilePageBloc, FilePageState>(
        builder: (BuildContext context, FilePageState state) {
          final children = state.children;

          return BlocBuilder<FilePageBloc, FilePageState>(
            buildWhen: (FilePageState previous, FilePageState current) =>
                previous.isGridView != current.isGridView,
            builder: (BuildContext context, FilePageState state) =>
                state.isGridView
                    ? _buildGridFileWidget(children)
                    : _getVerticalFileList(children,
                        scrollController: _scrollController,
                        onSecondaryTapUp: _onSecondaryTapUp,
                        onFileItemTap: _onFileItemTap),
          );
        },
        buildWhen: (FilePageState previous, FilePageState current) =>
            previous.children != current.children ||
            previous.children.length != current.children.length,
      );

  Widget _buildGridFileWidget(List<OpenDirChild> children) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      //假设窗口最大时横向为15个item
      final oneItemWidth =
          (_platformAdapter.webGetScreenSize()?.width ?? 0) / 15;

      debugPrint("oneItemWidth -> ${oneItemWidth}");

      final crossAxisCount = max(constraints.maxWidth ~/ oneItemWidth, 1);

      return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1 / 1.5, crossAxisCount: crossAxisCount),
          itemCount: children.length,
          itemBuilder: (BuildContext context, int index) {
            final file = children[index];
            final previewImg = file.previewImg;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapUp: (TapUpDetails details) async =>
                  await _onSecondaryTapUp(file, context, details, index),
              onTap: () => _onFileItemTap(file, index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    FractionallySizedBox(
                      widthFactor: 1,
                      child: AspectRatio(
                          aspectRatio: 1 / 1,
                          child: previewImg != null
                              ? Image.network(
                                  "${file.previewImgUrl}",
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  file.isDir == true
                                      ? Icons.folder
                                      : Icons.description_outlined,
                                  color: file.isDir == true
                                      ? Colors.orangeAccent
                                      : Colors.grey,
                                )),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                        child: AutoSizeText(
                      file.name ?? "",
                    )),
                  ],
                ),
              ),
            );
          });
    });
  }

  ///纵向的文件列表
  Widget _getVerticalFileList(List<OpenDirChild> children,
      {bool dirOnly = false, //只显示文件夹
      ScrollController? scrollController,
      Future<void> Function(OpenDirChild file, BuildContext context,
              TapUpDetails details, int index)?
          onSecondaryTapUp,
      void Function(OpenDirChild file, int index)? onFileItemTap}) {
    final List<OpenDirChild> items;

    if (dirOnly) {
      final copy = children.toList();
      copy.removeWhere((element) => element.isDir == false);
      items = copy;
    } else {
      items = children;
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: scrollController,
      shrinkWrap: true,
      separatorBuilder: (BuildContext context, int index) => _getDivider(),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final file = items[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
            child: Row(
              children: [
                Icon(
                  file.isDir == true
                      ? Icons.folder
                      : Icons.description_outlined,
                  color: file.isDir == true ? Colors.orangeAccent : Colors.grey,
                  size: 29,
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 3)),
                Text(file.name ?? "",
                    overflow: TextOverflow.ellipsis,
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
              onSecondaryTapUp?.call(file, context, details, index),
          onTap: () => onFileItemTap?.call(file, index),
        );
      },
    );
  }

  /// 云端任务列表
  Widget _buildTaskList(List<UpdateTaskEntity> tasks) {
    return ListView.separated(
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.path ?? "",
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: LinearProgressIndicator(
                      value: task.progress ?? 0,
                    )),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      task.displaySpeed,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                )
              ],
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) => _getDivider(),
        itemCount: tasks.length);
  }

  ///文件的点击事件
  void _onFileItemTap(OpenDirChild file, int index) {
    if (file.isDir == true) {
      bloc.add(ForwardEvent(index));
    } else {
      bloc.add(OpenFileEvent(index, context));
    }
  }

  ///右键点击处理
  Future<void> _onSecondaryTapUp(OpenDirChild file, BuildContext context,
      TapUpDetails details, int index) async {
    final mimeType = lookupMimeType(file.name ?? "");

    print(
        "onSecondaryTapUp: lookupMimeType->${lookupMimeType(file.name ?? "")}");

    // lookupMimeType(file.name);

    const idDelete = 0;
    const idDownload = 1;
    const idPlayVideo = 2;
    const idRename = 3;
    const idMove = 4;

    final data = {idDelete: "删除", idRename: "重命名", idMove: "移动到"};

    if (file.isDir == false) {
      data.addAll({idDownload: "下载"});
      if (mimeType?.startsWith("video") == true) {
        data.addAll({idPlayVideo: "使用potPlayer播放"});
      }
    }

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
          final fileName = file.name;
          if (fileName != null && fileName.isNotEmpty == true) {
            bloc.add(DeleteFileEvent([fileName]));
          }
        }
        break;
      case idDownload:
        bloc.add(DownloadFileEvent(index));
        break;
      case idPlayVideo:
        bloc.add(PlayVideoEvent(PlayVideoEvent.typePotPlayer, index));
        break;
      case idRename:
        final controller = TextEditingController(text: file.name);

        final confirm = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => AlertDialog(
                  title: const Text("请输入文件名"),
                  content: TextField(
                    controller: controller,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (controller.text == file.name) {
                            Util.showDefaultToast("请使用新的命名");
                          } else {
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: const Text("确定")),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("取消"))
                  ],
                ));

        final newName = controller.text;

        if (!confirm || newName.isEmpty) {
          return;
        }

        bloc.add(RenameEvent(index, newName));

        break;
      case idMove:
        //通知bloc加载目录数据
        bloc.add(ShowDirChooseDialogEvent());
        showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) => BlocProvider.value(
                value: bloc,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Column(
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 8,
                      ),
                      Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: BlocBuilder<FilePageBloc, FilePageState>(
                                buildWhen: (FilePageState previous,
                                        FilePageState current) =>
                                    previous.dirChoosePaths !=
                                    current.dirChoosePaths,
                                builder: (BuildContext context,
                                        FilePageState state) =>
                                    Visibility(
                                        maintainSize: true,
                                        maintainAnimation: true,
                                        maintainState: true,
                                        visible:
                                            state.dirChoosePaths.length > 1,
                                        child: BackButton(
                                          color: Colors.black45,
                                          onPressed: () {
                                            bloc.add(DirChooseBackwardEvent());
                                          },
                                        ))),
                          ),
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              "移动到",
                              textScaleFactor: 1.2,
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: BlocBuilder<FilePageBloc, FilePageState>(
                            buildWhen: (FilePageState previous,
                                    FilePageState current) =>
                                previous.dirChoosePaths !=
                                current.dirChoosePaths,
                            builder:
                                (BuildContext context, FilePageState state) =>
                                    _buildPathList(state.dirChoosePaths)),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Expanded(
                        child: BlocBuilder<FilePageBloc, FilePageState>(
                            buildWhen: (FilePageState previous,
                                    FilePageState current) =>
                                previous.dirChoosePaths !=
                                current.dirChoosePaths,
                            builder:
                                (BuildContext context, FilePageState state) {
                              final children =
                                  state.dirChoosePaths.last.children;
                              return children != null
                                  ? _getVerticalFileList(children,
                                      dirOnly: true,
                                      onFileItemTap:
                                          (OpenDirChild file, int index) =>
                                              bloc.add(
                                                  DirChooseForwardEvent(index)))
                                  : Container();
                            }),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Spacer(),
                            ElevatedButton(
                              style: _getButtonStyle(),
                              child: const Text(
                                "移到此处",
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                bloc.add(MoveFileEvent([index]));
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                )));
        break;
    }
  }

  ///当前路径横向列表
  Widget _buildPathList(List<OpenDirResult> paths) {
    final List<Widget> children = [];

    for (int index = 0; index < paths.length; index++) {
      children.add(Text(paths[index].name ?? "",
          style: TextStyle(
            color: index == paths.length - 1
                ? Theme.of(context).unselectedWidgetColor
                : Theme.of(context).primaryColorDark,
          )));
      if (index < paths.length - 1) {
        children.add(Text(
          "  >  ",
          style: TextStyle(color: Theme.of(context).primaryColorLight),
        ));
      }
    }
    return Row(
      children: children,
    );
  }

  Widget _buildLogoutAction() {
    return BlocBuilder<FilePageBloc, FilePageState>(
      buildWhen: (pre, curr) {
        return pre.selectMode != curr.selectMode;
      },
      builder: (context, state) {
        return Visibility(
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).popAndPushNamed("/login",
                  arguments: LoginArgs(LoginReason.logout));
            },
          ),
          visible: !state.selectMode,
        );
      },
    );
  }

  Widget _getDivider() => const Divider(height: 0.5, thickness: 0.5);

  Future<void> _nextFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer.complete();
    });
    await completer.future;
  }

// Widget _buildDirChooseWidget() {
//   bloc.state.children
// }
}
