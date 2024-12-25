// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';

import 'package:chewie/chewie.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart' as vp;
// Package imports:
import 'package:get/get.dart';
import 'package:lms_flutter_app/Controller/lesson_controller.dart';
import 'package:lms_flutter_app/Model/Course/Lesson.dart';
import 'package:lms_flutter_app/utils/widgets/connectivity_checker_widget.dart';
import 'package:video_player/video_player.dart';
// import 'package:pod_player/pod_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../utils/customer_timer.dart';

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
  // late VideoPlayerController videoPlayerController;
  late vp.VideoPlayerController videoPlayerControllerMain;
  ChewieController? chewieController;
  late TextEditingController _idController;
  late TextEditingController _seekToController;

  late PlayerState _playerState;
  late YoutubeMetaData _videoMetaData;
  // late FlickManager flickManager;
  double speed = 1;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  Offset position = Offset(0, 0);
  final GlobalKey _textKey = GlobalKey();
  double _top = 10;
  double _right = 10;
  late CustomTimer _timer;
  void checkVideo() {
    if (videoPlayerControllerMain.value.position >=
        videoPlayerControllerMain.value.duration - Duration(seconds: 3)) {
      // Assuming `updateLessonProgress` and `Lesson` are defined in your context.
      lessonController
          .updateLessonProgress(widget.lesson?.id, widget.lesson?.courseId, 1)
          .then((value) {
        Get.back();
      });
    }
  }

  Future<void> _showSpeedOptions(BuildContext context) async {
    final speeds = {
      '0.5x': 0.5,
      '0.75x': 0.75,
      'Normal': 1.0,
      '1.25x': 1.25,
      '1.5x': 1.5,
      '2.0x': 2.0,
    };

    final currentSpeed = videoPlayerControllerMain.value.playbackSpeed;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var entry in speeds.entries)
                ListTile(
                  title: Text(entry.key),
                  trailing: currentSpeed == entry.value
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    videoPlayerControllerMain.setPlaybackSpeed(entry.value);
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                title: const Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
      videoPlayerControllerMain =
          vp.VideoPlayerController.network(widget.videoID ?? '')
            ..initialize().then((_) {
              setState(() {
                chewieController = ChewieController(
                  videoPlayerController: videoPlayerControllerMain,
                  autoPlay: true,
                  showOptions: true,
                  showControls: true,
                  optionsBuilder: (context, chewieOptions) async {
                    await _showSpeedOptions(context);
                  },
                  overlay: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 8,
                      right: MediaQuery.of(context).size.width / 8,
                    ),
                    child: Text(
                      widget.email ?? '',
                      style: TextStyle(
                          backgroundColor: Colors.black.withOpacity(0.1),
                          color: Colors.white),
                    ),
                  ),

                  allowFullScreen: true,
                  allowPlaybackSpeedChanging: true,
                  // customControls: DefaultCustomControls(),
                  //CustomSpeedWidget(context),
                  looping: false,
                  showControlsOnInitialize: true,
                );

                chewieController?.addListener(checkVideo);
              });
            });
      // videoPlayerController =
      //     VideoPlayerController.networkUrl(Uri.parse('${widget.videoID}'))
      //       ..initialize().then((_) {
      //         setState(() {});
      //       });

      // flickManager = FlickManager(
      //     videoPlayerController: videoPlayerController,
      //     onVideoEnd: () async {
      //       if (widget.lesson != null) {
      //         await lessonController
      //             .updateLessonProgress(
      //                 widget.lesson?.id, widget.lesson?.courseId, 1)
      //             .then((value) {
      //           Get.back();
      //         });
      //       }
      //     });
    }
    _timer = CustomTimer(
      interval: Duration(seconds: 5),
      onTick: _updatePosition,
    );

    _timer.start();
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

  void _updatePosition() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define constraints
    final maxTop =
        screenHeight / 4; // Max value for `top` is half the screen height
    final maxRight =
        screenWidth / 4; // Max value for `right` is half the screen width

    setState(() {
      // Generate random values within the constrained range
      _top = Random().nextDouble() * maxTop;
      _right = Random().nextDouble() * maxRight;
    });

    debugPrint('Position updated: top=$_top, right=$_right');
  }

  @override
  void dispose() {
    if (widget.source == "Youtube") {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      // flickManager.dispose();
      videoPlayerControllerMain.dispose();
      chewieController?.dispose();
    }
    _timer.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //!
    if (widget.source == "Youtube") {
      return ConnectionCheckerWidget(
        child: LayoutBuilder(builder: (context, constraints) {
          final maxHeight = constraints.maxHeight / 2;

          return SafeArea(
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Scaffold(
                  backgroundColor: Colors.red,
                  body: WillPopScope(
                    onWillPop: () async => false,
                    child: YoutubePlayerBuilder(
                      onExitFullScreen: () {
                        SystemChrome.setPreferredOrientations(
                            DeviceOrientation.values);
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
                                .updateLessonProgress(widget.lesson?.id,
                                    widget.lesson?.courseId, 1)
                                .then((value) {
                              Get.back();
                            });
                          }
                        },
                      ),
                      builder: (context, player) => Scaffold(
                        body: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: Colors.black,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                      fit: BoxFit.fill,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          //! Player
                                          player,
                                          //! Email of user
                                          PositionedDirectional(
                                            top: _top.clamp(0,
                                                maxHeight), // Ensure top does not exceed maxHeight
                                            end: _right.clamp(
                                                0, constraints.maxWidth),
                                            child: Container(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  widget.email ?? '',
                                                  style: TextStyle(
                                                      backgroundColor: Colors
                                                          .black
                                                          .withOpacity(0.1)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )),
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
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? Container()
                    : PositionedDirectional(
                        top: _top.clamp(0,
                            maxHeight), // Ensure top does not exceed maxHeight
                        end: _right.clamp(0, constraints.maxWidth),
                        child: Container(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              widget.email ?? '',
                              style: TextStyle(
                                  backgroundColor:
                                      Colors.black.withOpacity(0.1)),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          );
        }),
      );
    }

    //!
    else {
      return LayoutBuilder(builder: (context, constraints) {
        final maxHeight = constraints.maxHeight / 1.5;

        return Stack(
          alignment: Alignment.center,
          children: [
            Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.blue,
                title: Text(
                  '${widget.lesson?.name ?? ''}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                toolbarHeight: kToolbarHeight,
                centerTitle: true,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              body:
                  // LayoutBuilder(builder: (context, constraints) {
                  //   Stack(
                  // children: [

                  Align(
                alignment: Alignment.center,
                child: chewieController != null
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Chewie(controller: chewieController!))
                    : Center(child: CircularProgressIndicator()),
              ),
              //  AspectRatio(
              //   aspectRatio: 16 / 9,
              //   child: Stack(
              //     children: [

              //       GestureDetector(
              //         onScaleStart: (ScaleStartDetails details) {
              //           _baseScale = _currentScale;
              //         },
              //         onScaleUpdate: (ScaleUpdateDetails details) {
              //           setState(() {
              //             _currentScale = _baseScale * details.scale;
              //           });
              //         },
              //         child: Transform.scale(
              //           scale: _currentScale,
              //           child: Stack(
              //             children: [
              //               FlickVideoPlayer(
              //                 flickManager: flickManager,
              //                 preferredDeviceOrientationFullscreen: [
              //                   DeviceOrientation.landscapeLeft,
              //                 ],
              //               ),
              //               PositionedDirectional(
              //                 top: 5,
              //                 end: 5,
              //                 child: Container(
              //                   child: Align(
              //                     alignment: Alignment.center,
              //                     child: Text(
              //                       widget.email ?? '',
              //                       style: TextStyle(
              //                           backgroundColor: Colors.black
              //                               .withOpacity(0.1)),
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),

              //       Positioned(
              //           right: 10, top: 0, child: speedControlWidget),

              //     ],
              //   ),
              // ),

              // widget.email == null
              //     ? SizedBox()
              //     : Positioned(
              //         left: position.dx,
              //         top: position.dy,
              //         child: GestureDetector(
              //           onPanUpdate: (details) {
              //             final RenderBox renderBox = _textKey.currentContext!
              //                 .findRenderObject() as RenderBox;
              //             final textSize = renderBox.size;
              //             setState(() {
              //               // Calculate new position and clamp it within screen bounds
              //               double newX =
              //                   (position.dx + details.delta.dx).clamp(
              //                 0.0,
              //                 constraints.maxWidth - textSize.width,
              //               );
              //               double newY =
              //                   (position.dy + details.delta.dy).clamp(
              //                 0.0,
              //                 constraints.maxHeight - textSize.height,
              //               );

              //               position = Offset(newX, newY);
              //             });
              //           },
              //           child: Container(
              //             padding:
              //                 EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //             decoration: BoxDecoration(
              //               color: Colors.black.withOpacity(0.6),
              //               borderRadius: BorderRadius.circular(8),
              //             ),
              //             child: Text(
              //               widget.email ?? "",
              //               maxLines: 1,
              //               key: _textKey,
              //               overflow: TextOverflow.ellipsis,
              //               style: TextStyle(
              //                 color: Colors.white,
              //                 fontSize: 16,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //   ],
              // )
              // }),
            ),
            // PositionedDirectional(
            //   top: _top.clamp(MediaQuery.of(context).size.height / 2,
            //       maxHeight), // Ensure top does not exceed maxHeight
            //   end: _right.clamp(0, constraints.maxWidth),
            //   child: Container(
            //     child: Container(
            //       child: Align(
            //         alignment: Alignment.center,
            //         child: Text(
            //           widget.email ?? '',
            //           style: TextStyle(
            //               backgroundColor: Colors.black.withOpacity(0.1)),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // Container(
            //   color: Colors.red,
            //   child: Text(
            //     widget.email ?? '',
            //     style:
            //         TextStyle(backgroundColor: Colors.black.withOpacity(0.1)),
            //   ),
            // ),
          ],
        );
      });
    }
  }

  Widget CustomSpeedWidget(BuildContext context) {
    return PopupMenuButton<double>(
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
        if (!videoPlayerControllerMain.value.isInitialized)
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
        videoPlayerControllerMain.setPlaybackSpeed(speed);
        setState(() {});
      },
    );
  }

  Widget TextWidget(String title, bool selected) {
    return Text(
      title,
      style: TextStyle(color: selected ? Colors.blue : Colors.white),
    );
  }
}
