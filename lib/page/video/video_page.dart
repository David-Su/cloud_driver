import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<StatefulWidget> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as VideoPageArgs;
    _controller = VideoPlayerController.networkUrl(Uri.parse(args.url))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }


  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as VideoPageArgs;

    // final controller =
    //     _controller ?? VideoPlayerController.networkUrl(Uri.parse(args.url))
    //       ..initialize().then((_) {
    //         // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
    //         setState(() {});
    //       });
    // _controller = controller;

    final controller = _controller;

    return Scaffold(
      body: Center(
        child: controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            controller.value.isPlaying ? controller.pause() : controller.play();
          });
        },
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}

class VideoPageArgs {
  final String url;

  VideoPageArgs(this.url);
}
