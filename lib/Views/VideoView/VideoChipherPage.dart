// Dart imports:
import 'dart:developer';
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:lms_flutter_app/Controller/lesson_controller.dart';
import 'package:lms_flutter_app/Model/Course/Lesson.dart';
import 'package:lms_flutter_app/utils/widgets/connectivity_checker_widget.dart';

import 'package:vdocipher_flutter/vdocipher_flutter.dart';

import '../../utils/customer_timer.dart';

class VdoCipherPage extends StatefulWidget {
  final EmbedInfo? embedInfo;
  final Lesson? lesson;
  String? email;
  VdoCipherPage({this.embedInfo, this.lesson, this.email});

  @override
  _VdoCipherPageState createState() => _VdoCipherPageState();
}

class _VdoCipherPageState extends State<VdoCipherPage> {
  final LessonController lessonController = Get.put(LessonController());
  VdoPlayerController? vdoPlayerController;
  final double aspectRatio = 16 / 9;
  ValueNotifier<bool> _isFullScreen = ValueNotifier(false);

  String nativeAndroidLibraryVersion = 'Unknown';
  final urlController = TextEditingController();
  double _top = 10;
  double _right = 10;
  late CustomTimer _timer;
  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft
    ]);

    // getOtpAndPlayBackInfo();

    log(widget.embedInfo.toString());
    _timer = CustomTimer(
      interval: Duration(seconds: 5),
      onTick: _updatePosition,
    );

    _timer.start();
    super.initState();
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
      _top = math.Random().nextDouble() * maxTop;
      _right = math.Random().nextDouble() * maxRight;
    });

    debugPrint('Position updated: top=$_top, right=$_right');
  }

  @override
  void dispose() {
    _timer.stop();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionCheckerWidget(
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VdoPlayer(
                              embedInfo: widget.embedInfo!,
                              onPlayerCreated: (controller) =>
                                  _onPlayerCreated(controller),
                              onError: _onVdoError,
                              aspectRatio: 16 / 9,
                              onFullscreenChange: _onFullscreenChange,
                            ), //! Email of user
                            PositionedDirectional(
                              top: _top,
                              end: _right,
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
                      ),
                      ValueListenableBuilder(
                        valueListenable: _isFullScreen,
                        builder: (context, value, child) {
                          return value != null
                              ? SizedBox.shrink()
                              : _nonFullScreenContent();
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 5,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        SystemChrome.setPreferredOrientations(
                            [DeviceOrientation.portraitUp]);
                      });
                      Get.back();
                    },
                    icon: Icon(Icons.cancel, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onVdoError(VdoError vdoError) {
    print("Oops, the system encountered a problem: " + vdoError.message);
  }

  _onEventChange(VdoPlayerController controller) {
    controller.addListener(() async {
      VdoPlayerValue value = controller.value;
      if (value.isEnded) {
        if (widget.lesson != null) {
          await lessonController
              .updateLessonProgress(
                  widget.lesson?.id, widget.lesson?.courseId, 1)
              .then((value) {
            Get.back();
          });
        }
      }
    });
  }

  _onPlayerCreated(VdoPlayerController controller) {
    setState(() {
      vdoPlayerController = controller;
      _onEventChange(vdoPlayerController!);
    });
  }

  _onFullscreenChange(isFullscreen) {
    setState(() {
      _isFullScreen.value = isFullscreen;
    });
  }

  _nonFullScreenContent() {
    return Container();
  }

  // double _getHeightForWidth(double width) {
  //   return width / aspectRatio;
  // }
}
