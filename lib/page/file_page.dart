import 'dart:convert';
import 'dart:html';

import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/dio_manager.dart';
import 'package:cloud_driver/model/entity/delete_file_entity.dart';
import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  ListFileResult? _allFile;
  final List<ListFileResult> _path = [];

  @override
  Widget build(BuildContext context) {
    final children = _path.isNotEmpty ? _path.last.children : null;

    Offset? _tapPosition;

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
            GestureDetector(
              child: Text("点我"),
              onTap: () => print("点了"),
            ),
            SizedBox(
                height: 20,
                child: ListView.separated(
                    separatorBuilder: (BuildContext context, int index) =>
                        const Text(" > "),
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: _path.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Center(child: Text(_path[index].name));
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
                          onTapDown: (TapDownDetails details) {
                            print("onTapDown");
                            _tapPosition = details.globalPosition;
                          },
                          onSecondaryTapUp: (TapUpDetails details) async {
                            if (file.isDir) {
                              return;
                            }

                            const idDelete = 0;
                            const idDownload = 1;

                            final data = {idDelete: "删除", idDownload: "下载"};

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
                                final paths = _path.map((e) => e.name).toList();
                                paths.add(file.name);

                                print("删除：" + paths.toString());

                                DioManager().doPost(
                                    api: NetworkConfig.apiDeleteFile,
                                    data: {"paths": paths},
                                    transformer: (json) =>
                                        DeleteFileEntity.fromJson(json),
                                    context: context);
                                break;
                              case idDownload:
                                break;
                            }
                          },
                          onTap: () {
                            if (file.isDir) {
                              setState(() {
                                _path.add(file);
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
        if (_path.length > 1) {
          setState(() {
            _path.removeAt(_path.length - 1);
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
      print(json.encode(value));
      setState(() {
        if (value != null) {
          _allFile = value;
          _path.add(value);
        }
      });
    });

    // 屏蔽浏览器默认的右键点击事件
    window.document.onContextMenu.listen((evt) => evt.preventDefault());

    super.initState();
  }

  Widget _getDivider() => const Divider(
        height: 20,
        color: Colors.grey,
      );
}
