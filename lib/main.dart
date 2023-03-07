import 'package:flutter/material.dart';
import 'package:qr_entrance/diva_service.dart';
import 'package:workmanager/workmanager.dart';

import 'home.dart';

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DivaService divaService = DivaService();
    if (await divaService.hasCredentials()) {
      try {
        await divaService.retrieveEntranceCode();
      } catch (e) {
        return false;
      }
    }
    return true;
  });
}

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // Workmanager().initialize(callbackDispatcher);
  // Workmanager().registerPeriodicTask(
  //     'qr-entrance-code-refresh', 'QR Entrance Code Refresh',
  //     frequency: const Duration(hours: 6),
  //     existingWorkPolicy: ExistingWorkPolicy.replace,
  //     constraints: Constraints(
  //         networkType: NetworkType.connected,
  //         requiresBatteryNotLow: true,
  //         requiresCharging: false,
  //         requiresDeviceIdle: false,
  //         requiresStorageNotLow: false),
  //     backoffPolicy: BackoffPolicy.exponential,
  //     backoffPolicyDelay: const Duration(minutes: 5));
  runApp(const EntranceApp());
}
