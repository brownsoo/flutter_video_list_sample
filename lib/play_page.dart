import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';

class PlayPage extends StatefulWidget {
  PlayPage({Key key}) : super(key: key);

  @override
  _PlayPageState createState() => _PlayPageState();
}

class Clip {
  final String fileName;
  final String title;
  final int runningTime;
  Clip(this.fileName, this.title, this.runningTime);

  String videoPath() {
    return "embed/$fileName.mp4";
  }

  String thumbPath() {
    return "embed/$fileName.png";
  }
}

class _PlayPageState extends State<PlayPage> {
  // VideoPlayerController _controller;
  // ChewieController _oldController;
  ChewieController _chewieController;
  // Future<void> _initializeVideoPlayerFuture;

  List<Clip> _clips = [
    new Clip("small", "small", 6),
    new Clip("earth", "earth", 13),
    new Clip("giraffe", "giraffe", 18),
    new Clip("particle", "particle", 11),
    new Clip("summer", "summer", 8)
  ];

  var _playingIndex = -1;
  var _disposed = false;
  var _isFullScreen = false;

  @override
  void initState() {
    Screen.keepOn(true);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _initializeAndPlay(0);
    super.initState();
  }

  @override
  void dispose() {
    _disposed = true;
    Screen.keepOn(false);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _chewieController?.dispose();
    _chewieController = null;
    super.dispose();
  }

  void _clearPrevious() {
    _chewieController?.exitFullScreen();
    _chewieController?.videoPlayerController?.removeListener(_onControllerUpdated);
    _chewieController?.removeListener(_onChewieUpdated);
    //_oldController?.dispose();
    _chewieController = null;
  }

  void _initializeAndPlay(int index) async {
    print("_initializeAndPlay ---------> $index / _isFullScreen=$_isFullScreen");
    final clip = _clips[index];
    final controller = ChewieController(
      videoPlayerController: VideoPlayerController.asset(clip.videoPath()),
      fullScreenByDefault: _isFullScreen,
      autoPlay: false,
      allowFullScreen: true,
      aspectRatio: 16 /9
    );

    //_oldController = _chewieController;
    _clearPrevious();
    _chewieController = controller;

    setState(() {
      debugPrint("----1");
    });

    Future.delayed(Duration(milliseconds: 100), () {
      controller.videoPlayerController
        ..initialize().then((_) {
          debugPrint("----------2");
          _playingIndex = index;

          controller.videoPlayerController.addListener(_onControllerUpdated);
          controller.addListener(_onChewieUpdated);
          controller.play();
          setState(() {});
        });
    });
  }

  void _onChewieUpdated() {
    final chewie = _chewieController;
    if (chewie == null || _disposed) return;
    debugPrint("+++++++++++ _onChewieUpdated ${chewie.isFullScreen}");
    // fullscreen
    // if (chewie.isFullScreen) {
    //   this._isFullScreen = true;
    //   debugPrint("+++++++++++ _isFullScreen $_isFullScreen");
    //   SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])
    //       .then((_) {
    //     setState(() {});
    //   });
    // } else if (!chewie.isFullScreen) {
    //   this._isFullScreen = false;
    //   debugPrint("+++++++++++ _isFullScreen $_isFullScreen");
    //   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    //     setState(() {});
    //   });
    // }
    // setState(() {});
  }

  var _isPlaying = false;
  var _isEndOfClip = false;

  Future<void> _onControllerUpdated() async {
    final chewie = _chewieController;
    if (chewie == null || _disposed) return;
    final controller = chewie.videoPlayerController;
    if (controller == null) return;
    if (!controller.value.initialized) return;
    final position = await controller.position;
    final duration = controller.value.duration;
    if (position == null || duration == null) return;

    final isPlaying = controller.value.isPlaying;
    final isEndOfClip = position.inMilliseconds > 0 && position.inSeconds == duration.inSeconds;
    
    if (position.inSeconds % 3 == 0)
      debugPrint(".");

    if (_isPlaying != isPlaying || _isEndOfClip != isEndOfClip) {
      _isPlaying = isPlaying;
      _isEndOfClip = isEndOfClip;
      debugPrint("$_playingIndex -----> isPlaying=$isPlaying / isEndPlaying=$isEndOfClip");
      if (isEndOfClip && !isPlaying) {
        debugPrint("handle NEXT ========================== ");
        final isComplete = _playingIndex == _clips.length - 1;
        if (isComplete) {
          print("played all!!");
          if (!_showingDialog) {
            _showingDialog = true;
            _showPlayedAllDialog().then((value) {
              _showingDialog = false;
            });
          }
        } else {
          _initializeAndPlay(_playingIndex + 1);
        }
      }
    }
  }

  bool _showingDialog = false;

  Future<bool> _showPlayedAllDialog() async {
    return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(child: Text("끝까지 재생되었습니다.")),
            actions: <Widget>[
              FlatButton(
                child: Text("닫기"),
                onPressed: () => Navigator.pop(context, true),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Play View"),
      ),
      body: !_isFullScreen
          ? Column(children: <Widget>[
              Container(
                child: _playView(),
                decoration: BoxDecoration(color: Colors.black),
              ),
              Expanded(
                child: _listView(),
              ),
            ])
          : Container(
              child: _playView(),
              decoration: BoxDecoration(color: Colors.black),
            ),
    );
  }

  void _onTapCard(int index) {
    _initializeAndPlay(index);
  }

  Widget _playView() {
    // FutureBuilder to display a loading spinner until finishes initializing
    final controller = _chewieController?.videoPlayerController;
    if (controller != null && controller.value.initialized) {
      return AspectRatio(
        //aspectRatio: controller.value.aspectRatio,
        aspectRatio: 16.0 / 9.0,
        child: Chewie(controller: _chewieController),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16.0 / 9.0,
        child: Center(
            child: Text(
          "준비중 ...",
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18.0),
        )),
      );
    }
  }

  Widget _listView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _clips.length,
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          splashColor: Colors.blue[100],
          onTap: () {
            _onTapCard(index);
          },
          child: _buildCard(index),
        );
      },
    ).build(context);
  }

  // todo: bind clip info
  Widget _buildCard(int index) {
    final clip = _clips[index];
    final playing = index == _playingIndex;
    String runtime;
    if (clip.runningTime > 60) {
      runtime = "${clip.runningTime ~/ 60}분 ${clip.runningTime % 60}초";
    } else {
      runtime = "${clip.runningTime % 60}초";
    }
    return Card(
      child: Container(
        padding: EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Image.asset(
                clip.thumbPath(),
                width: 70,
                height: 50,
                fit: BoxFit.fill,
              ),
            ),
            Expanded(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(clip.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Padding(
                      child: Text("$runtime", style: TextStyle(color: Colors.grey[500])),
                      padding: EdgeInsets.only(top: 3),
                    )
                  ]),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: playing
                  ? Icon(Icons.play_arrow)
                  : Icon(
                      Icons.play_arrow,
                      color: Colors.grey.shade300,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
