import 'package:flutter/services.dart';

class BrightnessService {
  static const platform = MethodChannel('de.sikupe.d7/native');

  Future<double> getBrightness() async {
    return await platform.invokeMethod('getBrightness');
  }

  setBrightness(double brightness) async {
    await platform.invokeMethod('setBrightness', {'brightness': brightness});
  }
}
