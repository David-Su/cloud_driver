import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';
import 'package:cloud_driver/page/file/base_page_state.dart';
import 'package:cloud_driver/page/video/video_page.dart';
import 'package:cloud_driver/route/PopupWindowRoute.dart';
import 'package:cloud_driver/util/util.dart';
import 'package:cloud_driver/widget/ExpandableFab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mime/mime.dart';

import '../file_page_bloc.dart';
import '../file_page_event.dart';
import '../file_page_state.dart';
import 'package:open_file/open_file.dart';

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FilePageState();
}

class _FilePageState extends BasePageState {
  final _scrollController = ScrollController();
  final _taskButtonKey = GlobalKey();
  final _platformAdapter = PlatformAdapter();
  //上传进度弹窗的key
  final _keyProgressDialog = GlobalKey();


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      bloc.add(FileListScrollEvent(_scrollController.position.pixels));
    });
    bloc.add(InitEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => bloc,
      child: MultiBlocListener(
        listeners: [
          _buildScrollPosChangeListener(),
        ],
        child: PopScope(
          child: Scaffold(
            appBar: AppBar(
              title: BlocBuilder<FilePageBloc, FilePageState>(
                  buildWhen: (pre, curr) {
                return pre.selectMode != curr.selectMode;
              }, builder: (context, state) {
                if (state.selectMode) {
                  final selectedCount = state.children
                      .where((element) => element.isSelected)
                      .length;
                  return Container(
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              bloc.add(CloseSelectModeEvent());
                            },
                            icon: const Icon(Icons.close)),
                        Text("已选择$selectedCount项")
                      ],
                    ),
                  );
                } else {
                  return const Text("文件");
                }
              }),
              automaticallyImplyLeading: false,
              shadowColor: Theme.of(context).colorScheme.shadow,
              actions: [
                BlocBuilder<FilePageBloc, FilePageState>(
                  buildWhen: (pre, curr) {
                    return pre.children != curr.children;
                  },
                  builder: (context, state) {
                    final selected =
                        state.children.where((element) => element.isSelected);
                    final selectedAllFile = selected.isNotEmpty &&
                        selected.every((element) => !element.isDir);
                    return Visibility(
                      child: IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: () {

                        },
                      ),
                      visible: selectedAllFile,
                    );
                  },
                ),
                BlocBuilder<FilePageBloc, FilePageState>(
                  buildWhen: (pre, curr) {
                    return pre.children != curr.children;
                  },
                  builder: (context, state) {
                    final hadSelected =
                        state.children.any((element) => element.isSelected);
                    return Visibility(
                      child: IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        onPressed: () async {
                          final files = state.children
                              .where((element) => element.isSelected);

                          final delete = await showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                    title: const Text("警告"),
                                    content: Text("确认删除这${files.length}个项目吗"),
                                    actions: [
                                      TextButton(
                                        child: const Text("取消"),
                                        onPressed: () => Navigator.of(context)
                                            .pop(false), //关闭对话框
                                      ),
                                      TextButton(
                                        child: const Text("删除"),
                                        onPressed: () {
                                          //执行删除操作
                                          Navigator.of(context)
                                              .pop(true); //关闭对话框
                                        },
                                      ),
                                    ],
                                  ));

                          if (delete) {
                            bloc.add(DeleteFileEvent(
                                files.map((e) => e.name).toList()));
                          }
                        },
                      ),
                      visible: hadSelected,
                    );
                  },
                ),
                BlocBuilder<FilePageBloc, FilePageState>(
                  buildWhen: (pre, curr) {
                    return pre.children != curr.children;
                  },
                  builder: (context, state) {
                    final hadSelected =
                        state.children.any((element) => element.isSelected);
                    return Visibility(
                      child: PopupMenuButton(
                          itemBuilder: (BuildContext context) => []),
                      visible: hadSelected,
                    );
                  },
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        key: _taskButtonKey,
                        onPressed: () {
                          if (bloc.state.updateTasks.isEmpty) {
                            ToastUtil.showDefaultToast("没有任务");
                            return;
                          }

                          final renderOjb =
                              _taskButtonKey.currentContext?.findRenderObject();

                          if (renderOjb is RenderBox) {
                            final offset = renderOjb.localToGlobal(Offset.zero);

                            final right = MediaQuery.of(context).size.width -
                                offset.dx -
                                renderOjb.size.width;
                            final top = offset.dy + renderOjb.size.height;

                            Navigator.push(
                                context,
                                PopupWindowRoute((BuildContext routeContext) =>
                                    PopupWindow(
                                      BlocProvider.value(
                                        value: bloc,
                                        child: BlocBuilder<FilePageBloc,
                                                FilePageState>(
                                            buildWhen: (FilePageState previous,
                                                    FilePageState current) =>
                                                previous.updateTasks !=
                                                current.updateTasks,
                                            builder: (BuildContext context,
                                                FilePageState state) {
                                              final tasks = state.updateTasks;

                                              return tasks.isNotEmpty
                                                  ? Container(
                                                      constraints: BoxConstraints(
                                                          maxWidth: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              2),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 20.w,
                                                              horizontal: 25.w),
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.w),
                                                          color: Colors.white),
                                                      child: _buildTaskList(
                                                          state.updateTasks),
                                                    )
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.w),
                                                          color: Colors.white),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 20.w,
                                                              horizontal: 35.w),
                                                      child: Text(
                                                        "没有进行中的任务",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                    );
                                            }),
                                      ),
                                      key: _keyProgressDialog,
                                      alignment: AlignmentDirectional.topEnd,
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
                      builder: (BuildContext context, FilePageState state) =>
                          IconButton(
                              onPressed: () => bloc.add(SwitchViewEvent()),
                              icon: Icon(
                                state.isGridView ? Icons.list : Icons.grid_view,
                                color: Colors.black45,
                              )),
                    ),
                  ],
                ),
                _buildPathList(),
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
            floatingActionButton: FloatingActionButton(
              onPressed: _onPressFab,
              child: const Icon(Icons.add),
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

  BlocListener<FilePageBloc, FilePageState> _buildScrollPosChangeListener() {
    return BlocListener<FilePageBloc, FilePageState>(
      listener: (BuildContext context, FilePageState state) async {
        await WidgetsBinding.instance.endOfFrame;
        final jumpTo = min(
            _scrollController.position.maxScrollExtent, state.fileListPosition);

        debugPrint(
            "jumpTo->${jumpTo}  max${_scrollController.position.maxScrollExtent}");

        _scrollController.jumpTo(jumpTo);
      },
      listenWhen: (FilePageState previous, FilePageState current) =>
          previous.fileListPosition != current.fileListPosition,
    );
  }

  void _onPressFab() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          final itemFolder =
              BottomSheetMenuItem(Icons.folder_open_outlined, "文件夹");
          final itemUpload =
              BottomSheetMenuItem(Icons.file_upload_outlined, "上传");

          final items = [
            itemFolder,
            itemUpload,
          ];

          return GridView.builder(
            shrinkWrap: true,
            itemCount: min(items.length, 3),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1 / 1,
              crossAxisCount: min(items.length, 3),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (item == itemFolder) {
                    await onPressCreateDir();
                  } else if (item == itemUpload) {
                    bloc.add(UploadFileEvent(false));
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant)),
                      child: Column(
                        children: [
                          Icon(item.icon),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 50.w,
                    ),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          );
        });
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

  Widget _buildGridFileWidget(List<ListFileResult> children) {
    return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: children.length,
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1 / 1.2, crossAxisCount: 3),
        itemBuilder: (BuildContext context, int index) {
          final file = children[index];
          final previewImg = file.previewImg;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (bloc.state.selectMode) {
                bloc.add(SelectEvent(index));
              } else {
                _onFileItemTap(file, index);
              }
            },
            onLongPress: () => bloc.add(SelectEvent(index)),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 10.w) +
                  EdgeInsets.only(top: 20.w),
              child: Stack(
                children: [
                  Column(
                    children: [
                      AspectRatio(
                          aspectRatio: 4 / 3,
                          child: previewImg != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25.w),
                                  child: Image.network(
                                    "${file.previewImgUrl}",
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  file.isDir
                                      ? Icons.folder
                                      : Icons.description_outlined,
                                  color: file.isDir
                                      ? Colors.orangeAccent
                                      : Colors.grey,
                                )),
                      SizedBox(
                        height: 10.w,
                      ),
                      Expanded(
                          child: Text(
                        file.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      )),
                    ],
                  ),
                  Visibility(
                    child: Container(
                      alignment: Alignment.topRight,
                      constraints: const BoxConstraints.expand(),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.w),
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3)),
                      child: Checkbox(
                          value: file.isSelected,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: const CircleBorder(),
                          onChanged: (value) {}),
                    ),
                    visible: file.isSelected,
                  ),
                ],
              ),
            ),
          );
        });
  }

  ///纵向的文件列表
  Widget _getVerticalFileList(List<ListFileResult> children,
      {bool dirOnly = false, //只显示文件夹
      ScrollController? scrollController,
      Future<void> Function(ListFileResult file, BuildContext context,
              TapUpDetails details, int index)?
          onSecondaryTapUp,
      void Function(ListFileResult file, int index)? onFileItemTap}) {
    final List<ListFileResult> items;

    if (dirOnly) {
      final copy = children.toList();
      copy.removeWhere((element) => !element.isDir);
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
                  file.isDir ? Icons.folder : Icons.description_outlined,
                  color: file.isDir ? Colors.orangeAccent : Colors.grey,
                  size: 29,
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 3)),
                Text(file.name,
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
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          final task = tasks[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.path ?? "",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: LinearProgressIndicator(
                    value: task.progress ?? 0,
                  )),
                  SizedBox(
                    width: 10.w,
                  ),
                  Text(
                    task.displaySpeed,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            ],
          );
        },
        separatorBuilder: (BuildContext context, int index) => _getDivider(),
        itemCount: tasks.length);
  }

  ///文件的点击事件
  void _onFileItemTap(ListFileResult file, int index) {
    if (file.isDir) {
      bloc.add(ForwardEvent(index));
    } else {
      bloc.add(OpenFileEvent(index,context));
    }
  }

  ///右键点击处理
  Future<void> _onSecondaryTapUp(ListFileResult file, BuildContext context,
      TapUpDetails details, int index) async {
    final mimeType = lookupMimeType(file.name);

    print("onSecondaryTapUp: lookupMimeType->${lookupMimeType(file.name)}");

    // lookupMimeType(file.name);

    const idDelete = 0;
    const idDownload = 1;
    const idPlayVideo = 2;
    const idRename = 3;
    const idMove = 4;

    final data = {idDelete: "删除", idRename: "重命名", idMove: "移动到"};

    if (!file.isDir) {
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
                        //执行删除操作
                        Navigator.of(context).pop(true); //关闭对话框
                      },
                    ),
                  ],
                ));

        if (delete) {}
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
                            ToastUtil.showDefaultToast("请使用新的命名");
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
                      SizedBox(
                        height: 15.w,
                      ),
                      _buildPathList(),
                      SizedBox(
                        height: 15.w,
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
                                          (ListFileResult file, int index) =>
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
                                bloc.add(MoveFileEvent(index));
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
  Widget _buildPathList() {
    final controller = ScrollController();
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.w),
        child: BlocBuilder<FilePageBloc, FilePageState>(
          builder: (BuildContext context, FilePageState state) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              controller.jumpTo(controller.position.maxScrollExtent);
            });

            final paths = state.paths;
            final List<Widget> children = [];

            for (int index = 0; index < paths.length; index++) {
              children.add(Text(paths[index].name,
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
          },
          buildWhen: (FilePageState previous, FilePageState current) =>
              previous.paths != current.paths,
        ),
      ),
    );
  }

  Widget _getDivider() => const Divider(height: 0.5, thickness: 0.5);

}

class BottomSheetMenuItem {
  final IconData icon;
  final String title;

  BottomSheetMenuItem(this.icon, this.title);
}
