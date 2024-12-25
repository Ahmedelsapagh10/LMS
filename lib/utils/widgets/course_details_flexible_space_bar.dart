import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:loader_overlay/loader_overlay.dart';
import 'package:octo_image/octo_image.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';

import '../../Config/app_config.dart';
import '../../Controller/myCourse_controller.dart';
import '../../Model/Course/CourseMain.dart';
import '../../Views/VideoView/VideoChipherPage.dart';
import '../../Views/VideoView/VideoPlayerPage.dart';
import '../../Views/VideoView/VimeoPlayerPage.dart';
import '../CustomSnackBar.dart';
import '../CustomText.dart';
import 'StarCounterWidget.dart';

// ignore: must_be_immutable
class CourseDetailsFlexilbleSpaceBar extends StatefulWidget {
  final CourseMain course;
  CourseDetailsFlexilbleSpaceBar(this.course);

  @override
  State<CourseDetailsFlexilbleSpaceBar> createState() =>
      _CourseDetailsFlexilbleSpaceBarState();
}

class _CourseDetailsFlexilbleSpaceBarState
    extends State<CourseDetailsFlexilbleSpaceBar> {
  final MyCourseController controller = Get.put(MyCourseController());

  double width = 0;

  double percentageWidth = 0;

  double height = 0;

  double percentageHeight = 0;

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    percentageWidth = width / 100;
    height = MediaQuery.of(context).size.height;
    percentageHeight = height / 100;

    return Container(
      child: Stack(
        fit: StackFit.expand,
        children: [
          OctoImage(
            image: NetworkImage('$rootUrl/${widget.course.image}'),
            placeholderBuilder: OctoPlaceholder.circularProgressIndicator(),
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return Image.asset('images/fcimg.png');
            },
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 26),
            color: Colors.black.withOpacity(0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back_outlined,
                        color: Colors.white,
                      ),
                      Text(
                        "${stctrl.lang["Back"]}",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                courseDescriptionTitle(
                    widget.course.title?['${stctrl.code.value}'] ?? ""),
                courseDescriptionPublisher(widget.course.user?.name ?? ''),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarCounterWidget(
                            value: double.tryParse(
                                    widget.course.review.toString()) ??
                                0,
                            color: Color(0xffFFCF23),
                            size: 10,
                          ),
                          SizedBox(
                            height: percentageHeight * 1,
                          ),
                          courseDescriptionPublisher('(' +
                              widget.course.review.toString() +
                              ') ' +
                              "${stctrl.lang["based on"]}" +
                              ' ' +
                              '${widget.course.reviews?.length.toString()}' +
                              ' ' +
                              "${stctrl.lang["review"]}"),
                        ],
                      ),
                    ),
                    widget.course.trailerLink != null &&
                            widget.course.host != "ImagePreview"
                        ? GestureDetector(
                            child: CircleAvatar(
                                radius: 20.0,
                                backgroundColor: Color(0xFFD7598F),
                                child: ClipRRect(
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                )),
                            onTap: () async {
                              //! done 3

                              if (widget.course.host == "Vimeo") {
                                var vimeoID = widget.course.trailerLink
                                    ?.replaceAll("/videos/", "");

                                Get.bottomSheet(
                                  VimeoPlayerPage(
                                    email: controller.profileData.value.email,
                                    videoTitle: "${widget.course.title}",
                                    videoId: '$rootUrl/vimeo/video/$vimeoID',
                                  ),
                                  backgroundColor: Colors.black,
                                  isScrollControlled: true,
                                );
                              }
                              //! done 1

                              else if (widget.course.host == "Youtube") {
                                Get.bottomSheet(
                                  VideoPlayerPage(
                                    "Youtube",
                                    videoID: widget.course.trailerLink,
                                    email: controller.profileData.value.email,
                                  ),
                                  backgroundColor: Colors.black,
                                  isScrollControlled: true,
                                );
                              }

                              //! done 4
                              else if (widget.course.host == "VdoCipher") {
                                await generateVdoCipherOtp(
                                        widget.course.trailerLink)
                                    .then((value) {
                                  if (value['otp'] != null) {
                                    final EmbedInfo embedInfo =
                                        EmbedInfo.streaming(
                                      otp: value['otp'],
                                      playbackInfo: value['playbackInfo'],
                                      embedInfoOptions: EmbedInfoOptions(
                                        autoplay: true,
                                      ),
                                    );

                                    Get.bottomSheet(
                                      VdoCipherPage(
                                        email:
                                            controller.profileData.value.email,
                                        embedInfo: embedInfo,
                                      ),
                                      backgroundColor: Colors.black,
                                      isScrollControlled: true,
                                    );
                                    context.loaderOverlay.hide();
                                  } else {
                                    context.loaderOverlay.hide();
                                    CustomSnackBar()
                                        .snackBarWarning(value['message']);
                                  }
                                });
                              }
                              //! done 2
                              else {
                                var videoUrl;
                                if (widget.course.host == "Self") {
                                  videoUrl = rootUrl +
                                      "/" +
                                      widget.course.trailerLink.toString();
                                }
                                Get.bottomSheet(
                                  VideoPlayerPage(
                                    "network",
                                    videoID: videoUrl,
                                    email: controller.profileData.value.email,
                                  ),
                                  backgroundColor: Colors.black,
                                  isScrollControlled: true,
                                );
                              }
                            },
                          )
                        : Container()
                  ],
                ),
                SizedBox(
                  height: percentageHeight * 1.5,
                ),
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Get.theme.cardColor,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Get.theme.primaryColor,
                            size: 14,
                          ),
                          SizedBox(
                            width: 1,
                          ),
                          widget.course.duration != null
                              ? courseStructure(getTimeString(int.parse(
                                          widget.course.duration.toString()))
                                      .toString() +
                                  " ${stctrl.lang["Hour(s)"]}")
                              : SizedBox.shrink(),
                        ],
                      ),
                    ),
                    Expanded(child: Container()),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Get.theme.cardColor,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.insert_chart_sharp,
                            color: Get.theme.primaryColor,
                            size: 14,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          courseStructure(
                              '${widget.course.courseLevel?.title?[stctrl.code.value] ?? widget.course.courseLevel?.title?['en']}'),
                        ],
                      ),
                    ),
                    Expanded(child: Container()),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Get.theme.cardColor,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.person_add_alt_1,
                            color: Get.theme.primaryColor,
                            size: 14,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          courseStructure(
                              widget.course.totalEnrolled.toString()),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future generateVdoCipherOtp(url) async {
    Uri apiUrl = Uri.parse('https://dev.vdocipher.com/api/videos/$url/otp');

    var response = await http.post(
      apiUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Apisecret $vdoCipherApiKey'
      },
    );
    var decoded = jsonDecode(response.body);
    return decoded;
  }
}
