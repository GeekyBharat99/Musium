import 'dart:io';
import 'dart:ui';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musium/API/api.dart';
import 'package:musium/UI/SearchPage.dart';
import 'package:musium/music.dart';
import 'package:musium/style/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:musium/UI/LocalSongs.dart';

var subscription;
var isconnectedToInternet = false;

class GlobalSongs extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<GlobalSongs>
    with AutomaticKeepAliveClientMixin<GlobalSongs> {
  bool get wantKeepAlive => true;
  bool fetchingSongs = false;

  checkConnectivityListener() {
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      // Got a new connectivity status!
      if (result == ConnectivityResult.none) {
        setState(() {
          isconnectedToInternet = false;
        });
      } else {
        setState(() {
          isconnectedToInternet = true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkConnectivityListener();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xff1c252a),
        statusBarColor: Colors.transparent,
      ),
    );
  }

  getSongDetails(String id, var context) async {
    try {
      await fetchSongDetails(id);
    } catch (e) {
      artist = "Unknown";
    }
    setState(() {
      checker = "Haa";
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioApp(
          id: id,
        ),
      ),
    );
  }

  downloadSong(id) async {
    String filepath;
    String filepath2;
    var status = await Permission.storage.status;
    if (status.isUndetermined || status.isDenied) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scaffoldBackgroundColor,
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Colors.transparent,
        bottomNavigationBar: kUrl != ""
            ? Container(
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  color: appbarColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                  child: GestureDetector(
                    onTap: () {
                      checker = "Nahi";
                      if (kUrl != "") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AudioApp()),
                        );
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5.0,
                          ),
                          child: IconButton(
                            icon: Icon(
                              MdiIcons.appleKeyboardControl,
                              size: 22,
                            ),
                            onPressed: null,
                            disabledColor: accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 0.0, top: 7, bottom: 7, right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.50,
                                  child: Text(
                                    title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: accent,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              Text(
                                artist,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(color: accentLight, fontSize: 15),
                              )
                            ],
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: playerState == PlayerState.playing
                              ? Icon(MdiIcons.pause)
                              : Icon(MdiIcons.playOutline),
                          color: accent,
                          splashColor: Colors.transparent,
                          onPressed: () {
                            setState(() {
                              if (audioManagerInstance.isPlaying) {
                                audioManagerInstance.playOrPause();
                              }
                              if (playerState == PlayerState.playing) {
                                audioPlayer.pause();
                                playerState = PlayerState.paused;
                              } else if (playerState == PlayerState.paused) {
                                audioPlayer.play(kUrl);
                                playerState = PlayerState.playing;
                              }
                            });
                          },
                          iconSize: 45,
                        )
                      ],
                    ),
                  ),
                ),
              )
            : SizedBox.shrink(),
        body: isconnectedToInternet
            ? ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      15.0,
                      8.0,
                      0.0,
                      8.0,
                    ),
                    child: Text(
                      "Top 20 Songs",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 22,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FutureBuilder(
                    future: topSongs(),
                    builder: (context, data) {
                      if (data.hasData)
                        return Container(
                          height: MediaQuery.of(context).size.height,
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                            ),
                            itemCount: 21,
                            itemBuilder: (context, index) {
                              return getTopSong(
                                  data.data[index]["image"],
                                  data.data[index]["title"],
                                  data.data[index]["more_info"]["artistMap"]
                                      ["primary_artists"][0]["name"],
                                  data.data[index]["id"]);
                            },
                          ),
                        );
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(35.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            : Center(
                child: Text(
                  "No Internet! Connect To Internet.",
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: "btn2",
          backgroundColor: appbarColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchGlobal(),
              ),
            );
          },
          child: Icon(
            Icons.search,
            color: accent,
            size: 30.0,
          ),
        ),
      ),
    );
  }

  Widget getTopSong(String image, String title, String subtitle, String id) {
    return InkWell(
      onTap: () {
        getSongDetails(id, context);
      },
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.17,
            width: MediaQuery.of(context).size.width * 0.4,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: CachedNetworkImageProvider(image),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title
                  .split("(")[0]
                  .replaceAll("&amp;", "&")
                  .replaceAll("&#039;", "'")
                  .replaceAll("&quot;", "\""),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
