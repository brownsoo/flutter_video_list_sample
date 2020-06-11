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
  VideoPlayerController _controller;

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
  var _isPlaying = false;
  var _isEndOfClip = false;
  var _progress = 0.0;
  var _showingDialog = false;

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
    exitFullScreen();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _clearPrevious() {
    _controller?.removeListener(_onControllerUpdated);
    _controller = null;
  }

  void _toggleFullscreen() async {
    if (_isFullScreen) {
      exitFullScreen();
    } else {
      enterFullScreen();
    }
  }

  void enterFullScreen() async {
    debugPrint("enterFullScreen");
    _isFullScreen = true;
    await SystemChrome.setEnabledSystemUIOverlays([]);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  void exitFullScreen() async {
    debugPrint("exitFullScreen");
    _isFullScreen = false;
    await SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _initializeAndPlay(int index) async {
    print("_initializeAndPlay ---------> $index / _isFullScreen=$_isFullScreen");
    final clip = _clips[index];
    final controller = VideoPlayerController.asset(clip.videoPath());

    _clearPrevious();
    _controller = controller;

    setState(() {
      debugPrint("----1");
    });

    Future.delayed(Duration(milliseconds: 100), () {
      controller
        ..initialize().then((_) {
          debugPrint("----------2");
          _playingIndex = index;
          controller.addListener(_onControllerUpdated);
          controller.play();
          setState(() {});
        });
    });
  }

  var _playSeconds = 0.0;
  Future<void> _onControllerUpdated() async {
    if (_disposed) return;
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.initialized) return;
    final position = await controller.position;
    final duration = controller.value.duration;
    if (position == null || duration == null) return;

    final isPlaying = controller.value.isPlaying;
    final isEndOfClip = position.inMilliseconds > 0 && position.inSeconds == duration.inSeconds;

    // handle progress
    final seconds = position.inMilliseconds / 200.0;
    if (isPlaying && _playSeconds != seconds) {
      _playSeconds = seconds;
      if (_disposed) return;
      setState(() {
        _progress = position.inMilliseconds.ceilToDouble() / duration.inMilliseconds.ceilToDouble();
      });
    }

    if (_isPlaying != isPlaying || _isEndOfClip != isEndOfClip) {
      _isPlaying = isPlaying;
      if (_isEndOfClip != isEndOfClip) {
        _isEndOfClip = isEndOfClip;
        debugPrint("updated -----> isPlaying=$isPlaying / isEndPlaying=$isEndOfClip");
        if (isEndOfClip && isPlaying) {
          debugPrint("========================== End of Clip / Handle NEXT ========================== ");
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
  }

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
      body: _isFullScreen
          ? Container(
              child: _playView(context),
              decoration: BoxDecoration(color: Colors.black),
            )
          : Column(children: <Widget>[
              Container(
                child: _playView(context),
                decoration: BoxDecoration(color: Colors.black),
              ),
              Expanded(
                child: _listView(),
              ),
            ]),
    );
  }

  void _onTapCard(int index) {
    _initializeAndPlay(index);
  }

  Widget _playView(BuildContext context) {
    // FutureBuilder to display a loading spinner until finishes initializing
    final controller = _controller;
    if (controller != null && controller.value.initialized) {
      return AspectRatio(
        //aspectRatio: controller.value.aspectRatio,
        aspectRatio: 16.0 / 9.0,
        child: Stack(
          children: <Widget>[
            VideoPlayer(controller),
            _controlView(context),
          ],
        ),
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

  Widget _controlView(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: FlatButton(
            onPressed: () async {
              if (_isPlaying) {
                _controller?.pause();
                _isPlaying = false;
              } else {
                final controller = _controller;
                if (controller != null) {
                  final position = await controller.position;
                  final isEnd = controller.value.duration.inSeconds == position.inSeconds;
                  if (isEnd) {
                    _initializeAndPlay(_playingIndex);
                  } else {
                    controller.play();
                  }
                }
              }
              setState(() {});
            },
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 56.0,
              color: Colors.white,
            ),
          ),
        ),
        Column(
          children: <Widget>[
            Expanded(child: Container()),
            Container(
                child: Row(
              children: <Widget>[
                SizedBox(width: 20),
                Expanded(
                    child: LinearProgressIndicator(
                  value: _progress,
                )),
                IconButton(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.yellow,
                  icon: Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFullscreen,
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

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
