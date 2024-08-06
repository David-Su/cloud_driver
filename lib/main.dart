import 'package:cloud_driver/config/config.dart';
import 'package:cloud_driver/manager/work_manager.dart' as work_manager;
import 'package:cloud_driver/page/file/mobile/file_page.dart'
    if (dart.library.html) 'package:cloud_driver/page/file/web/file_page.dart'
    as file_view;
import 'package:cloud_driver/page/login/login_page.dart';
import 'package:cloud_driver/page/video/video_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("main() 当前渠道->${ChannelConfig.channel}");
  work_manager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: (kIsWeb) ? const Size(1920, 1080) : const Size(1080, 1920),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Flutter Demo',
              theme: ThemeData(
                // This is the theme of your application.
                //
                // Try running your application with "flutter run". You'll see the
                // application has a blue toolbar. Then, without quitting the app, try
                // changing the primarySwatch below to Colors.green and then invoke
                // "hot reload" (press "r" in the console where you ran "flutter run",
                // or simply save your changes to "hot reload" in a Flutter IDE).
                // Notice that the counter didn't reset back to zero; the application
                // is not restarted.
                appBarTheme: AppBarTheme.of(context).copyWith(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white),
                primarySwatch: Colors.blue,
                useMaterial3: true,
              ),
              // initialRoute: "/login",
              routes: {
                "/login": (BuildContext context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments as LoginArgs?;
                  return LoginPage(
                    args: args,
                  );
                },
                "/file": (BuildContext context) => const file_view.FilePage(),
                "/video": (BuildContext context) {
                  final args = ModalRoute.of(context)?.settings.arguments
                      as VideoPageArgs?;
                  return VideoPage(
                    args: args,
                  );
                },
              },
              builder: FToastBuilder(),
              home: LoginPage(args: LoginArgs(LoginReason.init)),
            ));
  }
}
