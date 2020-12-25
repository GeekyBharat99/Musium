import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:musium/UI/LocalNowPlaying.dart';
import 'package:musium/UI/LocalSearchPage.dart';
import 'package:musium/style/colors.dart';
import 'package:audio_manager/audio_manager.dart';
import 'package:musium/music.dart';
import 'package:musium/HomePage.dart';
import 'package:admob_flutter/admob_flutter.dart';

var songslist = [];
bool isPlaying = false;
bool localSongStatus = false;
Duration duration;
Duration position;
double slider;
var playingIndex;
double sliderVolume;
var audioManagerInstance = AudioManager.instance;

PlayMode playMode = audioManagerInstance.playMode;

class LocalSongs extends StatefulWidget {
  @override
  _LocalSongsState createState() => _LocalSongsState();
}

class _LocalSongsState extends State<LocalSongs>
    with AutomaticKeepAliveClientMixin<LocalSongs> {
  bool get wantKeepAlive => true;
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  void setupAudio() {
    audioManagerInstance.onEvents((events, args) {
      switch (events) {
        case AudioManagerEvents.start:
          slider = 0;
          setState(() {});
          break;

        case AudioManagerEvents.seekComplete:
          slider = audioManagerInstance.position.inMilliseconds /
              audioManagerInstance.duration.inMilliseconds;
          setState(() {});
          break;
        case AudioManagerEvents.playstatus:
          isPlaying = audioManagerInstance.isPlaying;
          setState(() {});
          break;
        case AudioManagerEvents.timeupdate:
          slider = audioManagerInstance.position.inMilliseconds /
              audioManagerInstance.duration.inMilliseconds;
          audioManagerInstance.updateLrc(args["position"].toString());
          setState(() {});
          break;
        case AudioManagerEvents.ended:
          if (songslist.length == playingIndex + 1) {
            if (playerState == PlayerState.playing) {
              audioPlayer.pause();
              if (mounted)
                setState(() {
                  playerState = PlayerState.paused;
                });
            }
            setState(() {
              playingIndex = 0;
              audioManagerInstance.start(
                "file://${songslist[playingIndex].filePath}",
                songslist[playingIndex].title,
                auto: true,
                cover: "main_logo.png",
                desc: songslist[playingIndex].artist,
              );
            });
          } else {
            if (playerState == PlayerState.playing) {
              audioPlayer.pause();
              if (mounted)
                setState(() {
                  playerState = PlayerState.paused;
                });
            }
            setState(() {
              playingIndex = playingIndex + 1;
              audioManagerInstance.start(
                "file://${songslist[playingIndex].filePath}",
                songslist[playingIndex].title,
                auto: true,
                cover: "main_logo.png",
                desc: songslist[playingIndex].artist,
              );
            });
          }
          break;

        default:
          break;
      }
    });
  }

  fetchsongs() async {
    List<SongInfo> songs = await audioQuery.getSongs();

    var tempList = [];
    for (var i in songs) {
      if (!(i.displayName.contains('.aac'))) {
        tempList.add(i);
      }
    }

    setState(() {
      songslist = tempList;
    });
  }

  @override
  void initState() {
    fetchsongs();
    setupAudio();
    tabController.addListener(() {
      if (tabController.index == 0) {
        fetchsongs();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    audioManagerInstance.release();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d == null) return "--:--";
    int minute = d.inMinutes;
    int second = (d.inSeconds > 60) ? (d.inSeconds % 60) : d.inSeconds;
    String format = ((minute < 10) ? "0$minute" : "$minute") +
        ":" +
        ((second < 10) ? "0$second" : "$second");
    return format;
  }

  Widget songProgress(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          _formatDuration(audioManagerInstance.position),
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 5,
                  thumbColor: Colors.green[50],
                  overlayColor: accent,
                  thumbShape: RoundSliderThumbShape(
                    disabledThumbRadius: 5,
                    enabledThumbRadius: 5,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: 10,
                  ),
                  activeTrackColor: accent,
                  inactiveTrackColor: Colors.green[50],
                ),
                child: Slider(
                  value: slider ?? 0,
                  onChanged: (value) {
                    setState(() {
                      slider = value;
                    });
                  },
                  onChangeEnd: (value) {
                    if (audioManagerInstance.duration != null) {
                      Duration msec = Duration(
                          milliseconds:
                              (audioManagerInstance.duration.inMilliseconds *
                                      value)
                                  .round());
                      audioManagerInstance.seekTo(msec);
                    }
                  },
                )),
          ),
        ),
        Text(
          _formatDuration(audioManagerInstance.duration),
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: localSongStatus
            ? Container(
                height: MediaQuery.of(context).size.height * 0.127,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  color: appbarColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 5.0,
                  ),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        child: songProgress(context),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Icons.skip_previous),
                                iconSize: 35.0,
                                color: Colors.green[50],
                                onPressed: () {
                                  if (0 == playingIndex) {
                                    if (playerState == PlayerState.playing) {
                                      audioPlayer.pause();
                                      if (mounted)
                                        setState(() {
                                          playerState = PlayerState.paused;
                                        });
                                    }
                                    setState(() {
                                      playingIndex = songslist.length - 1;
                                      audioManagerInstance.start(
                                        "file://${songslist[playingIndex].filePath}",
                                        songslist[playingIndex].title,
                                        auto: true,
                                        cover: "main_logo.png",
                                        desc: songslist[playingIndex].artist,
                                      );
                                    });
                                  } else {
                                    if (playerState == PlayerState.playing) {
                                      audioPlayer.pause();
                                      if (mounted)
                                        setState(() {
                                          playerState = PlayerState.paused;
                                        });
                                    }
                                    setState(() {
                                      playingIndex = playingIndex - 1;
                                      audioManagerInstance.start(
                                        "file://${songslist[playingIndex].filePath}",
                                        songslist[playingIndex].title,
                                        auto: true,
                                        cover: "main_logo.png",
                                        desc: songslist[playingIndex].artist,
                                      );
                                    });
                                  }
                                }),
                            IconButton(
                              iconSize: 35.0,
                              color: Colors.green[50],
                              icon: audioManagerInstance.isPlaying
                                  ? Icon(Icons.pause)
                                  : Icon(Icons.play_arrow),
                              onPressed: () {
                                if (playerState == PlayerState.playing) {
                                  audioPlayer.pause();
                                  if (mounted)
                                    setState(() {
                                      playerState = PlayerState.paused;
                                    });
                                }
                                audioManagerInstance.playOrPause();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_next),
                              iconSize: 35.0,
                              color: Colors.green[50],
                              onPressed: () {
                                if (songslist.length == playingIndex + 1) {
                                  if (playerState == PlayerState.playing) {
                                    audioPlayer.pause();
                                    if (mounted)
                                      setState(() {
                                        playerState = PlayerState.paused;
                                      });
                                  }
                                  setState(() {
                                    playingIndex = 0;
                                    audioManagerInstance.start(
                                      "file://${songslist[playingIndex].filePath}",
                                      songslist[playingIndex].title,
                                      auto: true,
                                      cover: "main_logo.png",
                                      desc: songslist[playingIndex].artist,
                                    );
                                  });
                                } else {
                                  if (playerState == PlayerState.playing) {
                                    audioPlayer.pause();
                                    if (mounted)
                                      setState(() {
                                        playerState = PlayerState.paused;
                                      });
                                  }
                                  setState(() {
                                    playingIndex = playingIndex + 1;
                                    audioManagerInstance.start(
                                      "file://${songslist[playingIndex].filePath}",
                                      songslist[playingIndex].title,
                                      auto: true,
                                      cover: "main_logo.png",
                                      desc: songslist[playingIndex].artist,
                                    );
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox.shrink(),
        backgroundColor: scaffoldBackgroundColor,
        floatingActionButton: FloatingActionButton(
          heroTag: "btn1",
          backgroundColor: appbarColor,
          onPressed: () {
            Navigator.push(context,
                    MaterialPageRoute(builder: (conext) => LocalSearch()))
                .whenComplete(
              () => {
                setupAudio(),
              },
            );
          },
          child: Icon(
            Icons.search_sharp,
            color: accent,
            size: 30.0,
          ),
        ),
        body: songslist != null
            ? Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: songslist.length + 1,
                        itemBuilder: (context, index) {
                          if (songslist.length == 0) {
                            Center(
                              child: Text(
                                "You Don't Have Any Downloaded Song Now, Go To Online Section And Download Some To Play Offline.",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          if (index == songslist.length) {
                            return Padding(
                              padding: EdgeInsets.all(2.0),
                              child: AdmobBanner(
                                adUnitId:
                                    'ca-app-pub-8853110266408068/8793593621',
                                adSize: AdmobBannerSize.LARGE_BANNER,
                              ),
                            );
                          }

                          return Card(
                            color: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  playingIndex = index;
                                  localSongStatus = true;
                                });
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            LocalNowPlaying())).whenComplete(
                                  () => {
                                    setupAudio(),
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(10.0),
                              splashColor: accent,
                              hoverColor: accent,
                              focusColor: accent,
                              highlightColor: accent,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 25.0,
                                  backgroundColor: Colors.black,
                                  backgroundImage: songslist[index]
                                              .albumArtwork ==
                                          null
                                      ? AssetImage("main_logo.png")
                                      : FileImage(
                                          File(songslist[index].albumArtwork)),
                                ),
                                title: Text(
                                  songslist[index].title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  songslist[index].artist,
                                  style: TextStyle(color: Colors.green[50]),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
