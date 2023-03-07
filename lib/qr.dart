import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_entrance/brightness_service.dart';
import 'package:qr_entrance/diva_service.dart';
import 'package:qr_entrance/wifi_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRPage extends StatefulWidget {
  final void Function(bool) callback;

  const QRPage({super.key, required this.callback});

  @override
  State<StatefulWidget> createState() => _QRState(callback: callback);
}

class _QRState extends State<QRPage> with WidgetsBindingObserver {
  late DivaService _divaService;
  late WifiService _wifiService;
  final BrightnessService _brightnessService = BrightnessService();

  final void Function(bool) callback;

  String? qrCode;
  bool loadingCode = true;
  bool configuringWifi = false;
  bool connectedToD7Airlan = false;

  _QRState({required this.callback}) {
    _divaService = DivaService();
    _wifiService = WifiService(_divaService);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AppLifecycleState.resumed == state) {
      checkWifiState();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadCode();
    watchWifiState();
    increaseBrightness();
  }

  increaseBrightness() async {
    await _brightnessService.setBrightness(1);
  }

  checkWifiState() async {
    var connectedCorrectly = await _wifiService.connectedWithD7Airlan();

    setState(() {
      connectedToD7Airlan = connectedCorrectly;
    });
  }

  watchWifiState() async {
    await checkWifiState();

    await for (var connectedCorrectly
        in _wifiService.watchIfConnectedWithD7Airlan()) {
      setState(() {
        connectedToD7Airlan = connectedCorrectly;
      });

      if (connectedCorrectly) {
        await loadCodeIfNecessary();
      }
    }
  }

  connectToWifi() async {
    setState(() {
      configuringWifi = true;
    });

    try {
      await _wifiService.configureWifi();
      Fluttertoast.showToast(
        msg: "Configuration successful",
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error ${e.toString()}",
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    setState(() {
      configuringWifi = false;
    });
  }

  loadCodeIfNecessary() async {
    if (await _divaService.hasValidCode()) {
      return;
    }

    await loadCode();
  }

  loadCode() async {
    setState(() {
      qrCode = null;
      loadingCode = true;
    });

    String? code = null;
    try {
      code = await _divaService.retrieveOrGetEntranceCode();
    } catch (e) {}

    setState(() {
      qrCode = code;
      loadingCode = false;
    });
  }

  refreshCode() async {
    if (!(await _divaService.hasCredentials())) {
      await _divaService.clearCode();
      callback.call(false);
      return;
    }

    setState(() {
      loadingCode = true;
      qrCode = null;
    });

    String? code = null;
    try {
      code = await _divaService.retrieveEntranceCode();
    } catch (e) {}

    setState(() {
      qrCode = code;
      loadingCode = false;
    });
  }

  logout() async {
    await _divaService.logoutAndDeleteCredentials();
    callback.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(15),
              child: AspectRatio(
                aspectRatio: 1,
                child: loadingCode
                    ? Center(
                        child: const CircularProgressIndicator(),
                      )
                    : qrCode != null
                        ? QrImage(
                            data: qrCode!,
                          )
                        : Center(
                            child: Container(
                              margin: EdgeInsets.all(15),
                              child: Text(
                                'An error occurred. Please try again later!\n(Are you connected to d7-airlan?)',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
              ),
            ),
            // Container(
            //   margin: EdgeInsets.all(15),
            //   child: Visibility(
            //     child: Text(
            //       'Not connected to d7-airlan!\nNo Refresh possible!',
            //       style: TextStyle(
            //         color: Colors.red,
            //       ),
            //       textAlign: TextAlign.center,
            //     ),
            //     maintainInteractivity: false,
            //     maintainSize: true,
            //     maintainAnimation: true,
            //     maintainState: true,
            //     visible: !connectedToD7Airlan,
            //   ),
            // ),
            Container(
              margin: const EdgeInsets.all(15),
              child: TextButton(
                onPressed: connectedToD7Airlan ? refreshCode : null,
                style: ButtonStyle(
                    minimumSize:
                        MaterialStateProperty.all<Size>(const Size(250, 50)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35.0),
                            side: BorderSide(
                                color: connectedToD7Airlan
                                    ? Colors.blue
                                    : Colors.grey)))),
                child: Text(
                  connectedToD7Airlan
                      ? 'Refresh'
                      : 'Not connected to d7-airlan!\nNo Refresh possible!',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Container(
                margin: const EdgeInsets.all(15),
                child: TextButton(
                  onPressed: configuringWifi ? null : connectToWifi,
                  style: ButtonStyle(
                      minimumSize:
                          MaterialStateProperty.all<Size>(const Size(250, 50)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35.0),
                              side: BorderSide(
                                  color: configuringWifi
                                      ? Colors.grey
                                      : Colors.blue)))),
                  child: configuringWifi
                      ? const CircularProgressIndicator()
                      : const Text('Configure d7-airlan'),
                )),
            Container(
              margin: const EdgeInsets.all(15),
              child: TextButton(
                onPressed: logout,
                style: ButtonStyle(
                    minimumSize:
                        MaterialStateProperty.all<Size>(const Size(250, 50)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35.0),
                            side: const BorderSide(color: Colors.blue)))),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
