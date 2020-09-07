class VideoClip {
  final String fileName;
  final String thumbName;
  final String title;
  final String parent;
  int runningTime;

  VideoClip(this.title, this.fileName, this.thumbName, this.runningTime, this.parent);

  String videoPath() {
    return "$parent/$fileName";
  }

  String thumbPath() {
    return "$parent/$thumbName";
  }


  static List<VideoClip> localClips = [
    VideoClip("Small", "small.mp4", "small.png", 6, "embed"),
    VideoClip("Earth", "earth.mp4", "earth.png", 13, "embed"),
    VideoClip("Giraffe", "giraffe.mp4", "giraffe.png", 18, "embed"),
    VideoClip("Particle", "particle.mp4", "particle.png", 11, "embed"),
    VideoClip("Summer", "summer.mp4", "summer.png", 8, "embed")
  ];

  static List<VideoClip> remoteClips = [
    VideoClip("For Bigger Fun", "ForBiggerFun.mp4", "images/ForBiggerFun.jpg", 0, "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample"),
    VideoClip("Elephant Dream", "ElephantsDream.mp4", "images/ForBiggerBlazes.jpg", 0, "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample"),
    VideoClip("BigBuckBunny", "BigBuckBunny.mp4", "images/BigBuckBunny.jpg", 0, "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample"),
  ];
}

