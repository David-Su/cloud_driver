import 'dart:async';
import 'dart:math';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/model/entity/open_dir_entity.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';
import 'package:cloud_driver/page/file/base_page_state.dart';
import 'package:cloud_driver/page/login/login_page.dart';
import 'package:cloud_driver/page/video/video_page.dart';
import 'package:cloud_driver/route/PopupWindowRoute.dart';
import 'package:cloud_driver/util/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cloud_driver/page/file/file_page_bloc.dart';
import 'package:cloud_driver/page/file/file_page_event.dart';
import 'package:cloud_driver/model/state/file_page_state.dart';
import 'package:collection/collection.dart';

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
          _buildOpenVideoPageEventListener(),
        ],
        child: PopScope(
          child: Scaffold(
            appBar: AppBar(
              title: _buildAppBarTitle(),
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              shadowColor: Theme.of(context).colorScheme.shadow,
              actions: [
                _buildLogoutAction(),
                _buildDownloadAction(),
                _buildDeleteAction(),
                _buildMoreAction(),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BlocBuilder<FilePageBloc, FilePageState>(
                      buildWhen: (pre, cur) {
                        final preHadTask = pre.updateTasks.isNotEmpty;
                        final curHadTask = cur.updateTasks.isNotEmpty;
                        return preHadTask != curHadTask;
                      },
                      builder: (BuildContext context, FilePageState state) {
                        final curHadTask = state.updateTasks.isNotEmpty;
                        final button = IconButton(
                            key: _taskButtonKey,
                            onPressed: () {
                              if (bloc.state.updateTasks.isEmpty) {
                                Util.showDefaultToast("没有任务");

                                return;
                              }
                              _popupUploadDialog(context);
                            },
                            icon: Icon(
                              Icons.backup,
                              color: curHadTask
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black45,
                            ));

                        return curHadTask
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    strokeWidth: 6.w,
                                  ),
                                  button,
                                ],
                              )
                            : button;
                      },
                    ),
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

  void _popupUploadDialog(BuildContext context) {
    final renderOjb = _taskButtonKey.currentContext?.findRenderObject();

    if (renderOjb is RenderBox) {
      final offset = renderOjb.localToGlobal(Offset.zero);

      final right =
          MediaQuery.of(context).size.width - offset.dx - renderOjb.size.width;
      final top = offset.dy + renderOjb.size.height;

      Navigator.push(
          context,
          PopupWindowRoute((BuildContext routeContext) => PopupWindow(
                BlocProvider.value(
                  value: bloc,
                  child: BlocBuilder<FilePageBloc, FilePageState>(
                      buildWhen:
                          (FilePageState previous, FilePageState current) =>
                              previous.updateTasks != current.updateTasks,
                      builder: (BuildContext context, FilePageState state) {
                        final tasks = state.updateTasks;

                        return tasks.isNotEmpty
                            ? Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width / 2),
                                padding: EdgeInsets.symmetric(
                                    vertical: 20.w, horizontal: 25.w),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30.w),
                                    color: Colors.white),
                                child: _buildTaskList(state.updateTasks),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30.w),
                                    color: Colors.white),
                                padding: EdgeInsets.symmetric(
                                    vertical: 20.w, horizontal: 35.w),
                                child: Text(
                                  "没有进行中的任务",
                                  style: Theme.of(context).textTheme.bodyMedium,
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
  }

  BlocBuilder<FilePageBloc, FilePageState> _buildAppBarTitle() {
    return BlocBuilder<FilePageBloc, FilePageState>(buildWhen: (pre, curr) {
      return pre.selectMode != curr.selectMode;
    }, builder: (context, state) {
      if (state.selectMode) {
        final selectedCount =
            state.children.where((element) => element.isSelected).length;
        return Row(
          children: [
            IconButton(
                onPressed: () {
                  bloc.add(CloseSelectModeEvent());
                },
                icon: const Icon(Icons.close)),
            Text("已选择$selectedCount项")
          ],
        );
      } else {
        return Row(
          children: [
            BlocBuilder<FilePageBloc, FilePageState>(
              buildWhen: (pre, cur) {
                return pre.paths != cur.paths;
              },
              builder: (BuildContext context, FilePageState state) {
                return Visibility(
                    replacement: SizedBox(
                      width: 50.w,
                    ),
                    child: IconButton(
                        onPressed: () => bloc.add(BackEvent()),
                        icon: const Icon(Icons.arrow_back)),
                    visible: state.paths.length > 1);
              },
            ),
            SizedBox(
              width: 5.w,
            ),
            const Text("文件"),
          ],
        );
      }
    });
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

  ///状态栏下载action
  BlocBuilder<FilePageBloc, FilePageState> _buildDownloadAction() {
    return BlocBuilder<FilePageBloc, FilePageState>(
      buildWhen: (pre, curr) {
        return pre.children != curr.children;
      },
      builder: (context, state) {
        final selected = state.children.where((element) => element.isSelected);
        final selectedAllFile = selected.isNotEmpty &&
            selected.every((element) => element.isDir == false);
        return Visibility(
          child: IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {},
          ),
          visible: selectedAllFile,
        );
      },
    );
  }

  ///状态栏删除action
  BlocBuilder<FilePageBloc, FilePageState> _buildDeleteAction() {
    return BlocBuilder<FilePageBloc, FilePageState>(
      buildWhen: (pre, curr) {
        return pre.children != curr.children;
      },
      builder: (context, state) {
        final hadSelected = state.children.any((element) => element.isSelected);
        return Visibility(
          child: IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () async {
              final files =
                  state.children.where((element) => element.isSelected);

              final delete = await showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                        title: const Text("警告"),
                        content: Text("确认删除这${files.length}个项目吗"),
                        actions: [
                          TextButton(
                            child: const Text("取消"),
                            onPressed: () =>
                                Navigator.of(context).pop(false), //关闭对话框
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

              if (delete) {
                bloc.add(DeleteFileEvent(
                    files.map((e) => e.name).whereNotNull().toList()));
              }
            },
          ),
          visible: hadSelected,
        );
      },
    );
  }

  ///更多按钮
  Widget _buildMoreAction() {
    return BlocBuilder<FilePageBloc, FilePageState>(
      buildWhen: (pre, curr) {
        return pre.children != curr.children;
      },
      builder: (context, state) {
        final hadSelected = state.children.any((element) => element.isSelected);
        return Visibility(
          child: PopupMenuButton(
              itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      child: Text(
                        "移动到",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      onTap: () {
                        //通知bloc加载目录数据
                        bloc.add(ShowDirChooseDialogEvent());
                        _showMoveFileSheet(context);
                      },
                    )
                  ]),
          visible: hadSelected,
        );
      },
    );
  }

  ///文件移动操作洁界面
  void _showMoveFileSheet(BuildContext context) {
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
                                    visible: state.dirChoosePaths.length > 1,
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
                          textScaler: TextScaler.linear(1.2),
                          style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 8.w,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: BlocBuilder<FilePageBloc, FilePageState>(buildWhen:
                        (FilePageState previous, FilePageState current) {
                      return previous.dirChoosePaths != current.dirChoosePaths;
                    }, builder: (BuildContext context, FilePageState state) {
                      final controller = ScrollController();

                      return SingleChildScrollView(
                        controller: controller,
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.w, vertical: 20.w),
                          child: BlocBuilder<FilePageBloc, FilePageState>(
                            builder:
                                (BuildContext context, FilePageState state) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((timeStamp) {
                                controller.jumpTo(
                                    controller.position.maxScrollExtent);
                              });

                              final paths = state.dirChoosePaths;
                              final List<Widget> children = [];

                              for (int index = 0;
                                  index < paths.length;
                                  index++) {
                                children.add(Text(paths[index].name ?? "",
                                    style: TextStyle(
                                      color: index == paths.length - 1
                                          ? Theme.of(context)
                                              .unselectedWidgetColor
                                          : Theme.of(context).primaryColorDark,
                                    )));
                                if (index < paths.length - 1) {
                                  children.add(Text(
                                    "  >  ",
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .primaryColorLight),
                                  ));
                                }
                              }
                              return Row(
                                children: children,
                              );
                            },
                            buildWhen: (FilePageState previous,
                                    FilePageState current) =>
                                previous.dirChoosePaths !=
                                current.dirChoosePaths,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Expanded(
                    child: BlocBuilder<FilePageBloc, FilePageState>(
                        buildWhen: (FilePageState previous,
                                FilePageState current) =>
                            previous.dirChoosePaths != current.dirChoosePaths,
                        builder: (BuildContext context, FilePageState state) {
                          final children =
                              state.dirChoosePaths.lastOrNull?.children ?? [];
                          return _getVerticalFileList(children,
                              dirOnly: true,
                              onFileItemTap: (OpenDirChild file, int index) =>
                                  bloc.add(DirChooseForwardEvent(index)));
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Spacer(),
                        FilledButton(
                          // style: _getButtonStyle(),
                          child: Text(
                            "移到此处",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();

                            final children = bloc.state.children;
                            final indexes = children
                                .where((element) => element.isSelected)
                                .map((e) => children.indexOf(e))
                                .toList();

                            bloc.add(MoveFileEvent(indexes));
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )));
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

  BlocListener<FilePageBloc, FilePageState> _buildOpenVideoPageEventListener() {
    return BlocListener<FilePageBloc, FilePageState>(
      listener: (BuildContext context, FilePageState state) async {
        final event = state.openVideoPageEvent;
        if (event == null) return;
        Navigator.of(context)
            .pushNamed("/video", arguments: VideoPageArgs(event.url));
      },
      listenWhen: (FilePageState previous, FilePageState current) =>
          current.openVideoPageEvent != null,
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
                        onFileItemTap: _onFileItemTap),
          );
        },
        buildWhen: (FilePageState previous, FilePageState current) =>
            previous.children != current.children ||
            previous.children.length != current.children.length,
      );

  Widget _buildGridFileWidget(List<OpenDirChild> children) {
    return GridView.builder(
        // physics: const ClampingScrollPhysics(),
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
                                  child: FadeInImage.memoryNetwork(
                                    image: "${file.previewImgUrl}",
                                    placeholder: kTransparentImage,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  file.isDir == true
                                      ? Icons.folder
                                      : Icons.description_outlined,
                                  color: file.isDir == true
                                      ? Colors.orangeAccent
                                      : Colors.grey,
                                )),
                      SizedBox(
                        height: 10.w,
                      ),
                      Expanded(
                          child: Text(
                        file.name ?? "",
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
  Widget _getVerticalFileList(List<OpenDirChild> children,
      {bool dirOnly = false, //只显示文件夹
      ScrollController? scrollController,
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
                Expanded(
                  child: Text(
                    file.name ?? "",
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(file.displaySize),
              ],
              mainAxisSize: MainAxisSize.max,
            ),
          ),
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
  void _onFileItemTap(OpenDirChild file, int index) {
    if (file.isDir == true) {
      bloc.add(ForwardEvent(index));
    } else {
      bloc.add(OpenFileEvent(index, context));
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
