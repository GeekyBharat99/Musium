import 'package:flutter/material.dart';
import 'package:musium/style/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';

class MyNavigationDrawer extends StatelessWidget {
  final _menutextcolor = TextStyle(
    color: Colors.white,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
  );
  final _iconcolor = IconThemeData(
    color: accent,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: appbarColor,
        child: ListView(
          padding: EdgeInsets.all(0),
          children: [
            SizedBox(
              height: 2.0,
            ),
            Text(
              "Musium",
              style: TextStyle(
                color: accent,
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Image(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 3.5,
              image: AssetImage('main_logo.png'),
            ),
            Divider(
              thickness: 2.0,
              color: accent,
            ),
            ListTile(
              leading: IconTheme(
                data: _iconcolor,
                child: Icon(Icons.info),
              ),
              title: Text("Contact Us", style: _menutextcolor),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed("/contactUs");
              },
            ),
            ListTile(
              leading: IconTheme(
                data: _iconcolor,
                child: Icon(Icons.share),
              ),
              title: Text("Share with Friends", style: _menutextcolor),
              onTap: () {
                // you can modify message if you want.
                Share.share(
                    "Hi, I found an awesome Music app *Musium*\n\n*Listen Music Without Ads.* \n\ You can Download any song that you want and can Listen Offline as well. Listen Online Music Without Ads Along with Lyrics \n\n* Download Link:-  * \n\n 👇👇👇👇👇\n\n  https://play.google.com/store/apps/details?id=com.BharatTiwari.musium");
              },
            ),
            ListTile(
              leading: IconTheme(
                data: _iconcolor,
                child: Icon(Icons.rate_review),
              ),
              title: Text("Rate and Review", style: _menutextcolor),
              onTap: () async {
                Navigator.of(context).pop();
                const url =
                    'https://play.google.com/store/apps/details?id=com.BharatTiwari.musium';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not open App';
                }
              },
            ),
            ListTile(
              leading: IconTheme(
                data: _iconcolor,
                child: Icon(Icons.info),
              ),
              title: Text("NOTE", style: _menutextcolor),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed("/note");
              },
            ),
          ],
        ),
      ),
    );
  }
}
