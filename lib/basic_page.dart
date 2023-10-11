import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BasicPage extends StatefulWidget {
  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<BasicPage> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse('http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4');
    _controller = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text("Basic Play View"),
      ),
      body: Center(
        child: controller != null && controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            final controller = _controller;
            if (controller != null) {
              controller.value.isPlaying ? controller.pause() : controller.play();
            }
          });
        },
        child: Icon(
          (controller != null && controller.value.isPlaying) ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
