import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_driver/manager/platform/platform_adapter.dart';
import 'package:cloud_driver/model/entity/list_file_entity.dart';
import 'package:cloud_driver/model/entity/update_task_entity.dart';
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
import 'package:cloud_driver/page/file/file_page_state.dart';

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FilePageState();
}

class _FilePageState extends State{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}

