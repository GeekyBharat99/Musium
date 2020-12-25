import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musium/Navigation.dart';
import 'package:musium/UI/GlobalSongs.dart';
import 'package:musium/UI/LocalSongs.dart';
import 'package:musium/style/colors.dart';

TabController tabController;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appbarColor,
        drawer: Drawer(
          child: MyNavigationDrawer(),
        ),
        appBar: AppBar(
          centerTitle: true,
          elevation: 0.0,
          title: Text(
            "Musium",
            style: GoogleFonts.poppins(
              color: accent,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorWeight: 3.5,
            controller: tabController,
            tabs: [
              Tab(
                child: Text(
                  "DOWNLOADED",
                ),
              ),
              Tab(
                child: Text(
                  "ONLINE",
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: <Widget>[
            LocalSongs(),
            GlobalSongs(),
          ],
        ),
      ),
    );
  }
}
