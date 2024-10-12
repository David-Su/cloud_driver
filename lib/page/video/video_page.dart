import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideoPage extends StatefulWidget {
  final VideoPageArgs? args;

  const VideoPage({super.key, this.args});

  @override
  State<StatefulWidget> createState() => _VideoPageState2();
}

class _VideoPageState2 extends State<VideoPage> {
  late final VideoPlayerController _videoPlayerController;
  late final ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.args?.url ?? ""));
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
    );
    _videoPlayerController.initialize().then((value) => {setState(() {})});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    return _videoPlayerController.value.isInitialized
        ? SafeArea(
            child: Chewie(
            controller: chewieController,
          ))
        : Container(
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.dispose();
    _chewieController.dispose();
  }
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
    debugPrint("url:" + args.url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(args.url))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("data"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(padding: const EdgeInsets.only(top: 20.0)),
            const Text('With remote mp4'),
            Container(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    VideoPlayer(_controller),
                    // ClosedCaption(text: _controller.value.caption.text),
                    _ControlsOverlay(controller: _controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  State<StatefulWidget> createState() {
    return _ControlsOverlayState();
  }
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  double _sliderValue = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      final int duration = widget.controller.value.duration.inMilliseconds;
      final int position = widget.controller.value.position.inMilliseconds;

      double playProgress;
      if (position <= 0) {
        playProgress = 0;
      } else {
        playProgress = position / duration;
      }

      if (!_isDragging) {
        _sliderValue = playProgress;
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    final int duration = controller.value.duration.inMilliseconds;
    final int position = controller.value.position.inMilliseconds;

    int maxBuffering = 0;
    for (final DurationRange range in controller.value.buffered) {
      final int end = range.end.inMilliseconds;
      if (end > maxBuffering) {
        maxBuffering = end;
      }
    }
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.bottomCenter,
          child: IntrinsicHeight(
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 50),
                  reverseDuration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                      onTap: () {
                        controller.value.isPlaying
                            ? controller.pause()
                            : controller.play();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.w) +
                            EdgeInsets.only(left: 20.w, right: 10.w),
                        child: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      )),
                ),
                Expanded(
                    child: SliderTheme(
                        data: SliderThemeData(
                            overlayShape: SliderComponentShape.noThumb),
                        child: Slider(
                          value: _sliderValue,
                          onChanged: (double newValue) {
                            _sliderValue = newValue;
                            _isDragging = true;
                            controller.seekTo(Duration(
                                milliseconds: (duration * newValue).toInt()));
                            setState(() {});
                          },
                          onChangeEnd: (double newValue) {
                            _isDragging = false;
                          },
                        ))),
                SizedBox(
                  width: 10.w,
                ),
                Text(
                    style: const TextStyle(color: Colors.white),
                    '${_getDisplayTime(position)}:${_getDisplayTime(duration)}'),
                SizedBox(
                  width: 20.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _getDisplayTime(int millisecond) {
    int second = millisecond ~/ 1000;

    // 计算分钟和秒
    int minutes = second ~/ 60;
    int seconds = second % 60;

    // 格式化分钟和秒，确保它们都是两位数
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr';
  }
}

class VideoPageArgs {
  final String url;

  VideoPageArgs(this.url);
}
