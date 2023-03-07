import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_entrance/diva_service.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class WifiService {
  static const String d7AirlanName = '"d7-airlan"';

  static const platform = MethodChannel('de.sikupe.d7/native');
  final connectivity = Connectivity();
  final networkInfo = NetworkInfo();

  final DivaService _divaService;

  WifiService(this._divaService);

  configureWifi() async {
    final username = await _divaService.username;
    final password = await _divaService.password;

    final response = await http.get(Uri.parse('https://info.domus7.org/cert'));

    if (response.statusCode != 200) {
      throw Exception('Could not download certificate');
    }

    final certificate = response.bodyBytes;

    await platform.invokeMethod('configureWifi', {
      'username': username,
      'password': password,
      'certificate': certificate
    });
  }

  Stream<bool> watchIfConnectedWithD7Airlan() async* {
    await for (final event in connectivity.onConnectivityChanged) {
      if (ConnectivityResult.wifi == event) {
        yield await connectedWithD7Airlan();
      } else {
        yield false;
      }
    }
  }

  Future<bool> connectedWithD7Airlan() async {
    var location = await Permission.locationWhenInUse.isGranted;

    if (!location) {
      location = (await Permission.locationWhenInUse.request()) ==
          PermissionStatus.granted;
    }

    if (!location) {
      return true;
    }

    final con = (await connectivity.checkConnectivity());
    if (con == ConnectivityResult.wifi) {
      final wifiName = await networkInfo.getWifiName();
      if (wifiName == d7AirlanName) {
        return true;
      }
    }
    return false;
  }
}
