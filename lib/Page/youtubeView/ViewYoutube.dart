import 'package:flutter/material.dart';
import 'package:flutter_youtube_view/flutter_youtube_view.dart';
import 'package:get/get.dart';
import 'package:vozforums/Page/youtubeView/YoutubeController.dart';

class YoutubeView extends GetView<YoutubeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: false,
      extendBody: false,
      body: FlutterYoutubeView(
        onViewCreated: controller.onYoutubeCreated,
        listener: controller,
        params: YoutubeParam(
          videoId: Get.arguments[0],
          showUI: true,
          //startSeconds: 5 * 60.0,
          showYoutube: false,
          showFullScreen: false,
        ),
      ),
    );
  }
}