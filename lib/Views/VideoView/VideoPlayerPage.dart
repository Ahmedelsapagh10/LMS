import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Package imports:
import 'package:get/get.dart';
import 'package:lms_flutter_app/Controller/lesson_controller.dart';
import 'package:lms_flutter_app/Model/Course/Lesson.dart';
import 'package:lms_flutter_app/utils/widgets/connectivity_checker_widget.dart';
import 'package:video_player/video_player.dart';
// import 'package:pod_player/pod_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final String? videoID;
  final Lesson? lesson;
  final String? source;
  final String? email;

  VideoPlayerPage(this.source, {this.videoID, this.lesson, this.email});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with SingleTickerProviderStateMixin {
  // PodPlayerController? _podPlayerController;

  final LessonController lessonController = Get.put(LessonController());

  String? video;
  bool _isPlayerReady = false;
  late YoutubePlayerController _controller;
  late VideoPlayerController videoPlayerController;

  late TextEditingController _idController;
  late TextEditingController _seekToController;

  late PlayerState _playerState;
  late YoutubeMetaData _videoMetaData;
  late FlickManager flickManager;
  double speed = 1;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  Offset position = Offset(0, 0);
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    print('Video ID: ${widget.videoID}');
    print('Video Lesson: ${widget.lesson?.name}');
    print('___________Video Source: ${widget.lesson?.host}');
    if (widget.source == "Youtube") {
      _controller = YoutubePlayerController(
        initialVideoId: extractYouTubeVideoId('${widget.videoID}'),
        flags: const YoutubePlayerFlags(
          mute: false,
          autoPlay: true,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      )..addListener(listener);
      _idController = TextEditingController();
      _seekToController = TextEditingController();
      _videoMetaData = const YoutubeMetaData();
      _playerState = PlayerState.unknown;
      super.initState();
    } else {
      super.initState();
      videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse('${widget.videoID}'))
            ..initialize().then((_) {
              setState(() {});
            });

      flickManager = FlickManager(
          videoPlayerController: videoPlayerController,
          onVideoEnd: () async {
            if (widget.lesson != null) {
              await lessonController
                  .updateLessonProgress(
                      widget.lesson?.id, widget.lesson?.courseId, 1)
                  .then((value) {
                Get.back();
              });
            }
          });
    }
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
      });
    }
  }

  String extractYouTubeVideoId(String url) {
    RegExp regExp = RegExp(
      r'^.*(?:youtu.be\/|v\/|e\/|u\/\w+\/|embed\/|v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );

    Match? match = regExp.firstMatch(url);
    if (match?.groupCount == 1) {
      return match!.group(1)!;
    } else {
      // Return an empty string or throw an exception, depending on your use case.
      return '';
    }
  }

  @override
  void dispose() {
    if (widget.source == "Youtube") {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      flickManager.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speedControlWidget = PopupMenuButton<double>(
      child: Container(
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
        padding: EdgeInsets.all(8),
        child: Icon(
          Icons.speed,
          color: Colors.white,
          size: 24,
        ),
      ),
      color: Colors.black,
      constraints: BoxConstraints(maxWidth: 80),
      itemBuilder: (_) {
        if (!videoPlayerController.value.isInitialized)
          return [];
        else
          return [
            PopupMenuItem(
              child: TextWidget('0.25x', speed == 0.25),
              value: 0.25,
            ),
            PopupMenuItem(
              child: TextWidget('0.5x', speed == 0.5),
              value: 0.5,
            ),
            PopupMenuItem(
              child: TextWidget('1x', speed == 1),
              value: 1,
            ),
            PopupMenuItem(
              child: TextWidget('1.25x', speed == 1.25),
              value: 1.25,
            ),
            PopupMenuItem(
              child: TextWidget('1.5x', speed == 1.5),
              value: 1.5,
            ),
            PopupMenuItem(
              child: TextWidget('2x', speed == 2),
              value: 2,
            ),
          ];
      },
      onSelected: (value) {
        speed = value;
        videoPlayerController.setPlaybackSpeed(speed);
        setState(() {});
      },
    );
    if (widget.source == "Youtube") {
      return ConnectionCheckerWidget(
        child: SafeArea(
          child: WillPopScope(
            onWillPop: () async => false,
            child: YoutubePlayerBuilder(
              onExitFullScreen: () {
                SystemChrome.setPreferredOrientations(DeviceOrientation.values);
              },
              onEnterFullScreen: () {
                SystemChrome.setPreferredOrientations(
                    [DeviceOrientation.landscapeLeft]);
              },
              player: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: false,
                progressIndicatorColor: Colors.blueAccent,
                onReady: () {
                  setState(() {
                    _isPlayerReady = true;
                  });
                },
                onEnded: (data) async {
                  if (widget.lesson != null) {
                    await lessonController
                        .updateLessonProgress(
                            widget.lesson?.id, widget.lesson?.courseId, 1)
                        .then((value) {
                      Get.back();
                    });
                  }
                },
              ),
              builder: (context, player) => SafeArea(
                child: Scaffold(
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: Align(
                            alignment: Alignment.center,
                            child: FittedBox(fit: BoxFit.fill, child: player),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        left: 5,
                        child: IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(Icons.cancel, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        // backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(
            '${widget.lesson?.name}',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          toolbarHeight: kToolbarHeight,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onScaleStart: (ScaleStartDetails details) {
                          _baseScale = _currentScale;
                        },
                        onScaleUpdate: (ScaleUpdateDetails details) {
                          setState(() {
                            _currentScale = _baseScale * details.scale;
                          });
                        },
                        child: Transform.scale(
                          scale: _currentScale,
                          child: FlickVideoPlayer(
                            flickManager: flickManager,
                          ),
                        ),
                      ),
                      Positioned(right: 10, top: 0, child: speedControlWidget),
                    ],
                  ),
                ),
              ),
              widget.email == null
                  ? SizedBox()
                  : Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final RenderBox renderBox = _textKey.currentContext!
                              .findRenderObject() as RenderBox;
                          final textSize = renderBox.size;
                          setState(() {
                            // Calculate new position and clamp it within screen bounds
                            double newX =
                                (position.dx + details.delta.dx).clamp(
                              0.0,
                              constraints.maxWidth - textSize.width,
                            );
                            double newY =
                                (position.dy + details.delta.dy).clamp(
                              0.0,
                              constraints.maxHeight - textSize.height,
                            );

                            position = Offset(newX, newY);
                          });
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.email ?? "",
                            maxLines: 1,
                            key: _textKey,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        }),
      );
    }
  }

  Widget TextWidget(String title, bool selected) {
    return Text(
      title,
      style: TextStyle(color: selected ? Colors.blue : Colors.white),
    );
  }
}
