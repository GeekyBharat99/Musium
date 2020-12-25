import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:musium/UI/LocalNowPlaying.dart';
import 'package:musium/UI/LocalSongs.dart';
import 'package:musium/style/colors.dart';

class LocalSearch extends StatefulWidget {
  @override
  _LocalSearchState createState() => _LocalSearchState();
}

class _LocalSearchState extends State<LocalSearch> {
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;
  String query = "";

  String capitalize(String string) {
    if (string == null) {
      throw ArgumentError.notNull('string');
    }

    if (string.isEmpty) {
      return string;
    }

    return string[0].toUpperCase() + string.substring(1);
  }

  var results = [];

  searchSong(q) {
    results = [];
    for (var song in songslist) {
      if (song.title.contains(capitalize(q))) {
        setState(() {
          results.add(song);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Search",
          style: TextStyle(
            fontSize: 25.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: scaffoldBackgroundColor,
      resizeToAvoidBottomPadding: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 5.0),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: AdmobBanner(
                adUnitId: 'ca-app-pub-8853110266408068/8793593621',
                adSize: AdmobBannerSize.BANNER,
              ),
            ),
            TextField(
              onChanged: (String value) {
                query = value.trim();
                if (query != "") {
                  searchSong(query);
                }
              },
              autofocus: true,
              controller: searchBar,
              style: TextStyle(
                fontSize: 16,
                color: accent,
              ),
              cursorColor: Colors.green[50],
              decoration: InputDecoration(
                fillColor: Color(0xff263238),
                filled: true,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xff263238),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                  borderSide: BorderSide(color: accent),
                ),
                border: InputBorder.none,
                hintText: "Search...",
                hintStyle: TextStyle(
                  color: accent,
                ),
                contentPadding: const EdgeInsets.only(
                  left: 18,
                  right: 20,
                  top: 14,
                  bottom: 14,
                ),
              ),
            ),
            if (results.isNotEmpty)
              for (var song in results)
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: Card(
                    color: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: () {
                        var pIndex;
                        for (var i = 0; i < songslist.length; i++) {
                          if (songslist[i].title == song.title) {
                            pIndex = i;
                            setState(() {
                              playingIndex = pIndex;
                              localSongStatus = true;
                            });
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LocalNowPlaying()));
                            break;
                          }
                        }
                      },
                      splashColor: accent,
                      hoverColor: accent,
                      focusColor: accent,
                      highlightColor: accent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accent,
                          backgroundImage: song.albumArtwork == null
                              ? AssetImage("main_logo.png")
                              : FileImage(
                                  File(song.albumArtwork),
                                ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          song.artist,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                )
          ],
        ),
      ),
    );
  }
}
