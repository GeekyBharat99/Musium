import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musium/HomePage.dart';
import 'package:musium/UI/ContactUSPage.dart';
import 'package:musium/UI/NOTE.dart';
import 'package:musium/style/colors.dart';
import 'package:admob_flutter/admob_flutter.dart';

void main() async {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  ErrorWidget.builder = (FlutterErrorDetails details) => SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              "Loading...",
              style: TextStyle(
                color: accent,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
  WidgetsFlutterBinding.ensureInitialized();
  Admob.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    AudioManager.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Musium",
      theme: ThemeData(
        accentColor: accent,
        primaryColor: appbarColor,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: HomePage(),
      routes: <String, WidgetBuilder>{
        "/contactUs": (BuildContext context) => ContactUSPage(),
        "/note": (BuildContext context) => Note(),
      },
    );
  }
}
