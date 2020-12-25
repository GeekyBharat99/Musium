import 'dart:io';
import 'dart:ui';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:musium/style/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musium/UI/LocalSongs.dart';
import 'package:musium/music.dart';

class LocalNowPlaying extends StatefulWidget {
  @override
  _LocalNowPlayingState createState() => _LocalNowPlayingState();
}

class _LocalNowPlayingState extends State<LocalNowPlaying> {
  String _formatDuration(Duration d) {
    if (d == null) return "--:--";
    int minute = d.inMinutes;
    int second = (d.inSeconds > 60) ? (d.inSeconds % 60) : d.inSeconds;
    String format = ((minute < 10) ? "0$minute" : "$minute") +
        ":" +
        ((second < 10) ? "0$second" : "$second");
    return format;
  }

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

  Widget songProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    setupAudio();
    if (playerState == PlayerState.playing) {
      audioPlayer.pause();
      if (mounted)
        setState(() {
          playerState = PlayerState.paused;
        });
    }
    audioManagerInstance.start(
      "file://${songslist[playingIndex].filePath}",
      songslist[playingIndex].title,
      auto: true,
      cover: "main_logo.png",
      desc: songslist[playingIndex].artist,
    );
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
              image: songslist[playingIndex].albumArtwork == null
                  ? AssetImage("main_logo.png")
                  : FileImage(
                      File(songslist[playingIndex].albumArtwork),
                    ),
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
                              image: songslist[playingIndex].albumArtwork ==
                                      null
                                  ? AssetImage("main_logo.png")
                                  : FileImage(
                                      File(
                                          songslist[playingIndex].albumArtwork),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            bottom: 5.0,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                songslist[playingIndex].title ?? "Title",
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
                                songslist[playingIndex].album +
                                    "  |  " +
                                    songslist[playingIndex].artist,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accentLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              songProgress(context),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.skip_previous),
                                    iconSize: 50.0,
                                    color: Colors.green[50],
                                    onPressed: () {
                                      if (0 == playingIndex) {
                                        if (playerState ==
                                            PlayerState.playing) {
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
                                            desc:
                                                songslist[playingIndex].artist,
                                          );
                                        });
                                      } else {
                                        if (playerState ==
                                            PlayerState.playing) {
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
                                            desc:
                                                songslist[playingIndex].artist,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    iconSize: 50.0,
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
                                      iconSize: 50.0,
                                      color: Colors.green[50],
                                      onPressed: () {
                                        if (songslist.length ==
                                            playingIndex + 1) {
                                          if (playerState ==
                                              PlayerState.playing) {
                                            audioPlayer.pause();
                                            if (mounted)
                                              setState(() {
                                                playerState =
                                                    PlayerState.paused;
                                              });
                                          }
                                          setState(() {
                                            playingIndex = 0;
                                            audioManagerInstance.start(
                                              "file://${songslist[playingIndex].filePath}",
                                              songslist[playingIndex].title,
                                              auto: true,
                                              cover: "main_logo.png",
                                              desc: songslist[playingIndex]
                                                  .artist,
                                            );
                                          });
                                        } else {
                                          if (playerState ==
                                              PlayerState.playing) {
                                            audioPlayer.pause();
                                            if (mounted)
                                              setState(() {
                                                playerState =
                                                    PlayerState.paused;
                                              });
                                          }
                                          setState(() {
                                            playingIndex = playingIndex + 1;
                                            audioManagerInstance.start(
                                              "file://${songslist[playingIndex].filePath}",
                                              songslist[playingIndex].title,
                                              auto: true,
                                              cover: "main_logo.png",
                                              desc: songslist[playingIndex]
                                                  .artist,
                                            );
                                          });
                                        }
                                      }),
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(2.0),
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
}
