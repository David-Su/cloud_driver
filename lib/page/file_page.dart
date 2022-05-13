import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/model/entity/delete_file_entity.dart';
import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  ListFileResult? _allFile;
  final List<ListFileResult> _paths = [];

  @override
  Widget build(BuildContext context) {
    final children = _paths.isNotEmpty ? _paths.last.children : null;

    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("文件"),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          shrinkWrap: true,
          // mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
                onPressed: () {
                  final element = html.FileUploadInputElement();
                  element.multiple = false;
                  element.draggable = false;
                  element.click();

                  element.onChange.listen((event) async {
                    final files = element.files;
                    if (files == null || files.isEmpty == true) {
                      return;
                    }
                    final file = files[0];

                    final formData = html.FormData();
                    final token = (await SharedPreferences.getInstance())
                        .getString(SpConfig.keyToken);
                    final filePath = _getFilePath();
                    final request = html.HttpRequest();
                    int loaded = 0;
                    int total = 0;
                    StateSetter? dialogState;
                    bool uploadFinish = false;

                    request.open("POST",
                        "${NetworkConfig.urlBase}${NetworkConfig.apiUploadFile}?token=$token&path=$filePath");
                    request.upload.onProgress.listen((event) {
                      loaded = event.loaded ?? 0;
                      total = event.total ?? 0;

                      if (total != 0) {
                        dialogState?.call(() {});
                      }
                    });

                    request.onLoad.listen((event) {
                      print("上传完成");
                      dialogState?.call(() {
                        uploadFinish = true;
                      });
                      _refresh();
                    });
                    formData.appendBlob("file", file, file.name);
                    request.send(formData);

                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext dialogContext) =>
                            StatefulBuilder(builder:
                                (BuildContext context, StateSetter setState) {
                              if (uploadFinish) {
                                print("pop");
                                Navigator.of(dialogContext).pop();
                              }
                              dialogState = setState;
                              final progress =
                                  "${((loaded / total) * 100).toInt().toString()}%";
                              return Dialog(
                                child: Text(progress),
                              );
                            }));
                  });
                },
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text("上传文件")),
            SizedBox(
                height: 20,
                child: ListView.separated(
                    separatorBuilder: (BuildContext context, int index) =>
                        const Text(" > "),
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: _paths.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Center(child: Text(_paths[index].name));
                    })),
            _getDivider(),
            Expanded(
              child: children != null
                  ? ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (BuildContext context, int index) =>
                          _getDivider(),
                      itemCount: children.length,
                      itemBuilder: (BuildContext context, int index) {
                        final file = children[index];

                        return GestureDetector(
                          child: Row(
                            children: [
                              Icon(
                                file.isDir
                                    ? Icons.folder
                                    : Icons.description_outlined,
                                color: file.isDir
                                    ? Colors.orangeAccent
                                    : Colors.grey,
                              ),
                              Text(file.name)
                            ],
                          ),
                          onSecondaryTapUp: (TapUpDetails details) async {
                            if (file.isDir) {
                              return;
                            }

                            final mimeType = lookupMimeType(file.name);

                            print(
                                "onSecondaryTapUp: lookupMimeType->${lookupMimeType(file.name)}");

                            // lookupMimeType(file.name);

                            const idDelete = 0;
                            const idDownload = 1;
                            const idPlayVideo = 2;

                            final data = {idDelete: "删除", idDownload: "下载"};

                            if (mimeType?.startsWith("video") == true) {
                              data.addAll({idPlayVideo: "使用potPlayer播放"});
                            }

                            final overlay = Overlay.of(context)
                                ?.context
                                .findRenderObject() as RenderBox;
                            int? id = await showMenu<int>(
                                context: context,
                                items: data.entries
                                    .map((e) => PopupMenuItem(
                                          child: Text(e.value),
                                          value: e.key,
                                        ))
                                    .toList(),
                                position: RelativeRect.fromRect(
                                    Rect.fromLTRB(
                                        details.globalPosition.dx,
                                        details.globalPosition.dy,
                                        details.globalPosition.dx,
                                        details.globalPosition.dy),
                                    Offset.zero & overlay.size));

                            switch (id) {
                              case idDelete:
                                final paths =
                                    _paths.map((e) => e.name).toList();
                                paths.add(file.name);

                                print("删除：" + paths.toString());

                                final delete = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                          title: const Text("警告"),
                                          content: Text("确认删除${file.name}吗"),
                                          actions: [
                                            TextButton(
                                              child: const Text("取消"),
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false), //关闭对话框
                                            ),
                                            TextButton(
                                              child: const Text("删除"),
                                              onPressed: () {
                                                // ... 执行删除操作
                                                Navigator.of(context)
                                                    .pop(true); //关闭对话框
                                              },
                                            ),
                                          ],
                                        ));

                                if (delete) {
                                  await DioManager().doPost(
                                      api: NetworkConfig.apiDeleteFile,
                                      data: {"paths": paths},
                                      transformer: (json) =>
                                          DeleteFileEntity.fromJson(json),
                                      context: context);

                                  _refresh();
                                }

                                break;
                              case idDownload:
                                // print(
                                //     "download -> ${await _getDownloadUrl(file)}");
                                //
                                // final anchor = html.AnchorElement(
                                //     href: await _getDownloadUrl(file));
                                // // add the name
                                // anchor.download = file.name;
                                //
                                // // trigger download
                                // html.document.body?.append(anchor);
                                // anchor.click();
                                // anchor.remove();

                                print("下载链接 -> ${await _getDownloadUrl(file)}");

                                html.window
                                    .open(await _getDownloadUrl(file), "_self");

                                break;
                              case idPlayVideo:
                                final videoUrl = await _getDownloadUrl(file);
                                // js.context.callMethod(
                                //     'openVideoUrlWithSysProgram', [videoUrl]);

                                html.window
                                    .open("potplayer://$videoUrl", "_self");

                                break;
                            }
                          },
                          onTap: () {
                            if (file.isDir) {
                              setState(() {
                                _paths.add(file);
                              });
                            }
                          },
                        );
                      },
                    )
                  : const Text("没有子文件"),
            ),
          ],
        ),
      ),
      onWillPop: () async {
        if (_paths.length > 1) {
          setState(() {
            _paths.removeAt(_paths.length - 1);
          });
        }
        return false;
      },
    );
  }

  @override
  void initState() {
    DioManager()
        .doPost(
            api: NetworkConfig.apiListFile,
            transformer: (json) => ListFileEntity.fromJson(json),
            context: context)
        .then((value) {
      setState(() {
        if (value != null) {
          _allFile = value;
          _paths.add(value);
        }
      });
    });

    // 屏蔽浏览器默认的右键点击事件
    html.window.document.onContextMenu.listen((evt) => evt.preventDefault());

    super.initState();
  }

  Widget _getDivider() => const Divider(
        height: 20,
        color: Colors.grey,
      );

  String _getFilePath({ListFileResult? currentFile}) {
    final pathList = _paths.map((e) => e.name).toList();
    if (currentFile != null) {
      pathList.add(currentFile.name);
    }

    final filePaths = StringBuffer();
    filePaths.writeAll(pathList, ",");

    return filePaths.toString();
  }

  Future<String> _getDownloadUrl(ListFileResult currentFile) async {
    final sp = await SharedPreferences.getInstance();

    return "${NetworkConfig.urlBase}${NetworkConfig.apiDownloadFile}?token=${sp.getString(SpConfig.keyToken)}&filePaths=${_getFilePath(currentFile: currentFile)}";
  }

  Future<void> _refresh() async {
    var result = await DioManager().doPost(
        api: NetworkConfig.apiListFile,
        transformer: (json) => ListFileEntity.fromJson(json),
        context: context);

    if (result == null) {
      return;
    }

    final files = [result];

    for (int deep = 0; deep < _paths.length; deep++) {
      var replace = false;
      for (var element in files) {
        print("_refresh 第${deep}层->${_paths[deep].name}  对比 ${element.name}");

        if (element.name == _paths[deep].name) {
          _paths.replaceRange(deep, deep + 1, [element]);

          // print("_refresh 替换->${_paths[deep].name}");

          replace = true;
        }
      }
      //如果本层没有匹配的目录，则回退到上一层
      if (!replace) {
        _paths.sublist(0, deep);
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
        _paths.sublist(0, deep + 1);
        break;
      }
    }

    _paths.forEach((element) {
      final sb = new StringBuffer();
      sb.writeAll((element.children?.map((e) => e.name)) ?? [], ",");
      print("_refresh path->${element.name} children->${sb.toString()}");
    });

    setState(() {});
  }
}
