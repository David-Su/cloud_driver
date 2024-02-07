import 'package:flutter/material.dart';
import 'package:cloud_driver/page/file/mobile/file_page.dart'
if (dart.library.html) 'package:cloud_driver/page/file/web/file_page.dart'
as file_view;

import 'file_page_bloc.dart';
import 'file_page_event.dart';
abstract class BasePageState extends State<file_view.FilePage>{

  @protected
  late final FilePageBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = FilePageBloc(context);
  }

  @protected
  onPressCreateDir() async{
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

    bloc.add(CreateDirEvent(name));
  }

}
