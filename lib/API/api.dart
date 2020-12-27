import 'dart:convert';
import 'package:des_plugin/des_plugin.dart';
import 'package:http/http.dart' as http;

List searchedList = [];
List topSongsList = [];
String kUrl = "",
    checker,
    image = "",
    title = "",
    album = "",
    artist = "",
    lyrics,
    has_320,
    rawkUrl;
String key = "YOUR-KEY";
String decrypt = "";

Future<List> fetchSongsList(searchQuery) async {
  String searchUrl =
      "YOUR-OWN-API=" +
          searchQuery +
          "YOUR-OWN-API";
  var res = await http.get(searchUrl, headers: {"Accept": "application/json"});
  var resEdited = (res.body).split("-->");
  var getMain = json.decode(resEdited[1]);

  searchedList = getMain["songs"]["data"];
  for (int i = 0; i < searchedList.length; i++) {
    searchedList[i]['title'] = searchedList[i]['title']
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");

    searchedList[i]['more_info']['singers'] = searchedList[i]['more_info']
            ['singers']
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");
  }
  return searchedList;
}

Future<List> topSongs() async {
  String topSongsUrl =
      "YOUR-OWN-API";
  var songsListJSON =
      await http.get(topSongsUrl, headers: {"Accept": "application/json"});
  var songsList = json.decode(songsListJSON.body);
  topSongsList = songsList["list"];
  for (int i = 0; i < topSongsList.length; i++) {
    topSongsList[i]['title'] = topSongsList[i]['title']
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");
    topSongsList[i]["more_info"]["artistMap"]["primary_artists"][0]["name"] =
        topSongsList[i]["more_info"]["artistMap"]["primary_artists"][0]["name"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"");
    topSongsList[i]['image'] =
        topSongsList[i]['image'].toString().replaceAll("150x150", "500x500");
  }
  return topSongsList;
}

Future fetchSongDetails(songId) async {
  String songUrl =
      "YOUR-OWN-API" +
          songId;
  var res = await http.get(songUrl, headers: {"Accept": "application/json"});
  var resEdited = (res.body).split("-->");
  var getMain = json.decode(resEdited[1]);

  title = (getMain[songId]["title"])
      .toString()
      .split("(")[0]
      .replaceAll("&amp;", "&")
      .replaceAll("&#039;", "'")
      .replaceAll("&quot;", "\"");
  image = (getMain[songId]["image"]).replaceAll("150x150", "500x500");
  album = (getMain[songId]["more_info"]["album"])
      .toString()
      .replaceAll("&quot;", "\"")
      .replaceAll("&#039;", "'")
      .replaceAll("&amp;", "&");

  try {
    artist =
        getMain[songId]['more_info']['artistMap']['primary_artists'][0]['name'];
  } catch (e) {
    artist = "-";
  }

  if (getMain[songId]["more_info"]["has_lyrics"] == "true") {
    String lyricsUrl =
        "YOUR-OWN-API=" +
            songId +
            "YOUR-OWN-API";
    var lyricsRes =
        await http.get(lyricsUrl, headers: {"Accept": "application/json"});
    var lyricsEdited = (lyricsRes.body).split("-->");
    var fetchedLyrics = json.decode(lyricsEdited[1]);
    lyrics = fetchedLyrics["lyrics"].toString().replaceAll("<br>", "\n");
  } else {
    lyrics = "null";
    String lyricsApiUrl =
        "YOUR-OWN-API" + artist + "/" + title;
    var lyricsApiRes =
        await http.get(lyricsApiUrl, headers: {"Accept": "application/json"});
    var lyricsResponse = json.decode(lyricsApiRes.body);
    if (lyricsResponse['status'] == true && lyricsResponse['lyrics'] != null) {
      lyrics = lyricsResponse['lyrics'];
    }
  }

  has_320 = getMain[songId]["more_info"]["320kbps"];
  kUrl = await DesPlugin.decrypt(
      key, getMain[songId]["more_info"]["encrypted_media_url"]);

  rawkUrl = kUrl;

  final client = http.Client();
  final request = http.Request('HEAD', Uri.parse(kUrl))
    ..followRedirects = false;
  final response = await client.send(request);

  kUrl = (response.headers['location']);
  artist = (getMain[songId]["more_info"]["artistMap"]["primary_artists"][0]
          ["name"])
      .toString()
      .replaceAll("&quot;", "\"")
      .replaceAll("&#039;", "'")
      .replaceAll("&amp;", "&");
}
