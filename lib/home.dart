import 'package:flutter/material.dart';
import 'package:qr_entrance/diva_service.dart';
import 'package:qr_entrance/qr.dart';

import 'login.dart';

class EntranceApp extends StatelessWidget {
  const EntranceApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ':D7 QR Entrance',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final DivaService _divaService = DivaService();

  bool hasCredentials = false;
  bool isInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isInitialized
          ? hasCredentials
              ? QRPage(callback: updateHasCredentials)
              : LoginPage(callback: updateHasCredentials)
          : InitPage(),
    );
  }

  updateHasCredentials(bool hasCreds) {
    setState(() {
      hasCredentials = hasCreds;
    });
  }

  @override
  void initState() {
    super.initState();

    () async {
      final hasCreds = await _divaService.hasCredentials();
      if (hasCreds) {
        final isLoggedIn = await _divaService.isLoggedIn();
        if (!isLoggedIn) {
          try {
            await _divaService.loginBasedOnSavedCredentials();
            setState(() {
              hasCredentials = true;
            });
          } catch (e) {
            await _divaService.logoutAndDeleteCredentials();
          }
        }
      }
      final hasValidCode = await _divaService.hasValidCode();
      if (hasValidCode) {
        setState(() {
          hasCredentials = true;
        });
      }
      setState(() {
        isInitialized = true;
      });
    }();
  }
}

class InitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                margin: EdgeInsets.all(15),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Image.asset('assets/logo-domus7-colored-small.png'),
                )),
            Container(
              margin: EdgeInsets.all(15),
              child: CircularProgressIndicator(),
            )
          ],
        ),
      ),
    );
  }
}
