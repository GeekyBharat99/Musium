import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayer/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musium/API/api.dart';
import 'package:musium/style/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:musium/UI/LocalSongs.dart';

String status = 'hidden';
AudioPlayer audioPlayer;
PlayerState playerState;

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class AudioApp extends StatefulWidget {
  final id;

  const AudioApp({Key key, this.id}) : super(key: key);
  @override
  AudioAppState createState() => AudioAppState();
}

@override
class AudioAppState extends State<AudioApp> {
  Duration duration;
  Duration position;

  get isPlaying => playerState == PlayerState.playing;

  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  downloadSong(id) async {
    String filepath;
    String filepath2;
    var status = await Permission.storage.status;
    if (status.isUndetermined || status.isDenied) {
      // code of read or write file in external storage (SD card)
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
    }
    status = await Permission.storage.status;
    await fetchSongDetails(id);
    if (status.isGranted) {
      ProgressDialog pr = ProgressDialog(context);
      pr = ProgressDialog(
        context,
        type: ProgressDialogType.Normal,
        isDismissible: false,
        showLogs: false,
      );

      pr.style(
        backgroundColor: Color(0xff263238),
        elevation: 4,
        textAlign: TextAlign.left,
        progressTextStyle: TextStyle(color: Colors.white),
        message: "Downloading " + title,
        messageTextStyle: TextStyle(color: accent),
        progressWidget: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      );
      await pr.show();

      final filename = title + ".m4a";
      final artname = title + "_artwork.jpg";
      //Directory appDocDir = await getExternalStorageDirectory();
      String dlPath = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_MUSIC);
      await File(dlPath + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
      await File(dlPath + "/" + artname)
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
      if (has_320 == "true") {
        kUrl = rawkUrl.replaceAll("_96.mp4", "_320.mp4");
        final client = http.Client();
        final request = http.Request('HEAD', Uri.parse(kUrl))
          ..followRedirects = false;
        final response = await client.send(request);

        kUrl = (response.headers['location']);
        final request2 = http.Request('HEAD', Uri.parse(kUrl))
          ..followRedirects = false;
        final response2 = await client.send(request2);
        if (response2.statusCode != 200) {
          kUrl = kUrl.replaceAll(".mp4", ".mp3");
        }
      }
      var request = await HttpClient().getUrl(Uri.parse(kUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = File(filepath);

      var request2 = await HttpClient().getUrl(Uri.parse(image));
      var response2 = await request2.close();
      var bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2);

      await file.writeAsBytes(bytes);
      await file2.writeAsBytes(bytes2);

      final tag = Tag(
        title: title,
        artist: artist,
        artwork: filepath2,
        album: album,
        lyrics: lyrics,
        genre: null,
      );

      final tagger = Audiotagger();
      await tagger.writeTags(
        path: filepath,
        tag: tag,
      );
      await Future.delayed(const Duration(seconds: 1), () {});
      await pr.hide();

      if (await file2.exists()) {
        await file2.delete();
      }

      Fluttertoast.showToast(
          msg: "Download Complete!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    } else if (status.isDenied || status.isPermanentlyDenied) {
      Fluttertoast.showToast(
          msg: "Storage Permission Denied!\nCan't Download Songs",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    } else {
      Fluttertoast.showToast(
          msg: "Permission Error!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.values[50],
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
          fontSize: 14.0);
    }
  }

  void initAudioPlayer() {
    if (audioPlayer == null) {
      audioPlayer = AudioPlayer();
    }
    setState(() {
      if (checker == "Haa") {
        stop();
        if (audioManagerInstance.isPlaying) {
          audioManagerInstance.playOrPause();
        }
        play();
      }
      if (checker == "Nahi") {
        if (playerState == PlayerState.playing) {
          if (audioManagerInstance.isPlaying) {
            audioManagerInstance.playOrPause();
          }
          play();
        } else {
          if (audioManagerInstance.isPlaying) {
            audioManagerInstance.playOrPause();
          }
          play();
          pause();
        }
      }
    });

    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => {if (mounted) setState(() => position = p)});

    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        {
          if (mounted) setState(() => duration = audioPlayer.duration);
        }
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
        if (mounted)
          setState(() {
            position = duration;
          });
      }
    }, onError: (msg) {
      if (mounted)
        setState(() {
          playerState = PlayerState.stopped;
          duration = Duration(seconds: 0);
          position = Duration(seconds: 0);
        });
    });
  }

  Future play() async {
    await audioPlayer.play(kUrl);

    if (mounted)
      setState(() {
        playerState = PlayerState.playing;
      });
  }

  Future pause() async {
    await audioPlayer.pause();

    setState(() {
      playerState = PlayerState.paused;
    });
  }

  Future stop() async {
    await audioPlayer.stop();
    if (mounted)
      setState(() {
        playerState = PlayerState.stopped;
        position = Duration();
      });
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    if (mounted)
      setState(() {
        isMuted = muted;
      });
  }

  void onComplete() {
    if (mounted) setState(() => playerState = PlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Now Playing",
            style: GoogleFonts.poppins(
              fontSize: 25.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 35,
              color: accent,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(image),
              fit: BoxFit.fill,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
              ),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(
                      8.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              image: CachedNetworkImageProvider(image),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5.0,
                            bottom: 5.0,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 25.0,
                                  color: accentLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                album + "  |  " + artist,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accentLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Builder(builder: (context) {
                                      return FlatButton(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18.0)),
                                          color: Colors.black12,
                                          onPressed: () {
                                            showBottomSheet(
                                              backgroundColor:
                                                  Colors.transparent,
                                              context: context,
                                              builder: (context) => Container(
                                                decoration: BoxDecoration(
                                                  color: appbarColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        const Radius.circular(
                                                            18.0),
                                                    topRight:
                                                        const Radius.circular(
                                                      18.0,
                                                    ),
                                                  ),
                                                ),
                                                height: 400,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 10.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          IconButton(
                                                              icon: Icon(
                                                                Icons
                                                                    .arrow_back_ios,
                                                                color: accent,
                                                                size: 20,
                                                              ),
                                                              onPressed: () => {
                                                                    Navigator.pop(
                                                                        context)
                                                                  }),
                                                          Expanded(
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      right:
                                                                          42.0),
                                                              child: Center(
                                                                child: Text(
                                                                  "Lyrics",
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        accent,
                                                                    fontSize:
                                                                        30,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    lyrics != "null"
                                                        ? Expanded(
                                                            flex: 1,
                                                            child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        6.0),
                                                                child: Center(
                                                                  child:
                                                                      SingleChildScrollView(
                                                                    child: Text(
                                                                      lyrics,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            16.0,
                                                                        color:
                                                                            accentLight,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                )),
                                                          )
                                                        : Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 120.0),
                                                            child: Center(
                                                              child: Container(
                                                                child: Text(
                                                                  "No Lyrics available!",
                                                                  style: TextStyle(
                                                                      color:
                                                                          accentLight,
                                                                      fontSize:
                                                                          25),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            "Lyrics",
                                            style: TextStyle(color: accent),
                                          ));
                                    }),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 5.0),
                                    child: IconButton(
                                      iconSize: 30.0,
                                      color: accent,
                                      icon: Icon(MdiIcons.downloadOutline),
                                      onPressed: () => downloadSong(widget.id),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        _buildPlayer(),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 10.0,
                          ),
                          child: AdmobBanner(
                            adUnitId: 'ca-app-pub-8853110266408068/8793593621',
                            adSize: AdmobBannerSize.LARGE_BANNER,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() => Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            duration == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(35.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  )
                : Slider(
                    activeColor: accent,
                    inactiveColor: Colors.green[50],
                    value: position?.inMilliseconds?.toDouble() ?? 0.0,
                    onChanged: (double value) {
                      return audioPlayer.seek((value / 1000).roundToDouble());
                    },
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble()),
            if (duration != null) _buildProgressView(),
          ],
        ),
      );

  Row _buildProgressView() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            position != null
                ? "${positionText ?? ''} ".replaceFirst("0:0", "0")
                : duration != null
                    ? durationText
                    : '',
            style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
          ),
          Column(
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isPlaying
                      ? Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xff4db6ac),
                                  Color(0xff00c754),
                                  Color(0xff61e88a),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(100)),
                          child: IconButton(
                            onPressed: isPlaying ? () => pause() : null,
                            iconSize: 40.0,
                            icon: Icon(MdiIcons.pause),
                            color: Color(0xff263238),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xff4db6ac),
                                  Color(0xff00c754),
                                  Color(0xff61e88a),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(100)),
                          child: IconButton(
                            onPressed: isPlaying ? null : () => play(),
                            iconSize: 40.0,
                            icon: Padding(
                              padding: const EdgeInsets.only(left: 2.2),
                              child: Icon(MdiIcons.playOutline),
                            ),
                            color: Color(0xff263238),
                          ),
                        ),
                ],
              ),
            ],
          ),
          Text(
            position != null
                ? "${durationText ?? ''}".replaceAll("0:", "")
                : duration != null
                    ? durationText
                    : '',
            style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
          ),
        ],
      );
}
