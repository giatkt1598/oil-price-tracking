import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/fuel_price_repository.dart';
import '../data/petrolimex_price_service.dart';
import '../data/widget_data_sync.dart';

class PriceRefreshWorker {
  static const refreshTaskUniqueName = 'petrolimex_price_refresh_periodic';
  static const refreshTaskName = 'refresh_petrolimex_prices';

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      refreshTaskUniqueName,
      refreshTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  static Future<void> runOnce() async {
    final repository = FuelPriceRepository(
      service: PetrolimexPriceService(),
      widgetSync: const WidgetDataSync(),
    );
    await repository.refresh();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await PriceRefreshWorker.runOnce();
    return true;
  });
}
