import 'package:flutter/material.dart';
import 'package:qr_entrance/diva_service.dart';

import 'home.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

@pragma('vm:entry-point')
void refreshCode() {
  () async {
    DivaService divaService = DivaService();
    if (await divaService.hasCredentials()) {
      try {
        await divaService.retrieveEntranceCode();
      } catch (e) {}
    }
  }();
}

void main() async {
  // Be sure to add this line if initialize() call happens before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  await AndroidAlarmManager.initialize();

  runApp(const EntranceApp());

  final int refreshCodeId = 123;
  await AndroidAlarmManager.periodic(
      const Duration(hours: 24), refreshCodeId, refreshCode,
      startAt: DateTime(2023, 1, 1, 5, 30));
}
