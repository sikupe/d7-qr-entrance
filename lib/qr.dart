import 'package:flutter/material.dart';
import 'package:qr_entrance/diva_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRPage extends StatefulWidget {
  final void Function(bool) callback;

  const QRPage({super.key, required this.callback});

  @override
  State<StatefulWidget> createState() => _QRState(callback: callback);
}

class _QRState extends State<QRPage> {
  final DivaService _divaService = DivaService();

  final void Function(bool) callback;

  String? qrCode;
  bool loading = true;

  _QRState({required this.callback});

  @override
  void initState() {
    super.initState();
    loadCode();
  }

  loadCode() async {
    setState(() {
      qrCode = null;
      loading = true;
    });

    String? code = null;
    try {
      code = await _divaService.retrieveOrGetEntranceCode();
    } catch (e) {}

    setState(() {
      qrCode = code;
      loading = false;
    });
  }

  refreshCode() async {
    if (!(await _divaService.hasCredentials())) {
      await _divaService.clearCode();
      callback.call(false);
      return;
    }

    setState(() {
      loading = true;
      qrCode = null;
    });

    String? code = null;
    try {
      code = await _divaService.retrieveEntranceCode();
    } catch (e) {}

    setState(() {
      qrCode = code;
      loading = false;
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
                child: loading
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
            Container(
              margin: const EdgeInsets.all(15),
              child: TextButton(
                onPressed: refreshCode,
                style: ButtonStyle(
                    minimumSize:
                        MaterialStateProperty.all<Size>(const Size(250, 50)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35.0),
                            side: const BorderSide(color: Colors.blue)))),
                child: const Text('Refresh'),
              ),
            ),
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
                )),
          ],
        ),
      ),
    );
  }
}
