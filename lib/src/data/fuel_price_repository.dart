import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fuel_price_snapshot.dart';
import 'petrolimex_price_service.dart';
import 'widget_data_sync.dart';

class FuelPriceRepository {
  FuelPriceRepository({
    required PetrolimexPriceService service,
    required WidgetDataSync widgetSync,
  }) : _service = service,
       _widgetSync = widgetSync;

  static const _snapshotKey = 'fuel_price_snapshot';
  static const _lastErrorMessageKey = 'fuel_price_last_error_message';
  static const _lastErrorAtKey = 'fuel_price_last_error_at';

  final PetrolimexPriceService _service;
  final WidgetDataSync _widgetSync;

  Future<FuelPriceSnapshot?> loadCachedSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return FuelPriceSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      await prefs.remove(_snapshotKey);
      return null;
    }
  }

  Future<RefreshError?> loadLastError() async {
    final prefs = await SharedPreferences.getInstance();
    final message = prefs.getString(_lastErrorMessageKey);
    final occurredAtRaw = prefs.getString(_lastErrorAtKey);
    if (message == null || occurredAtRaw == null) {
      return null;
    }
    final occurredAt = DateTime.tryParse(occurredAtRaw);
    if (occurredAt == null) {
      return RefreshError(message: message, occurredAt: DateTime.now());
    }
    return RefreshError(message: message, occurredAt: occurredAt);
  }

  Future<RefreshResult> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final snapshot = await _service.fetchPrices();
      await prefs.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
      await prefs.remove(_lastErrorMessageKey);
      await prefs.remove(_lastErrorAtKey);
      await _widgetSync.updateWithSnapshot(snapshot);
      return RefreshResult(snapshot: snapshot);
    } on Object catch (error) {
      final refreshError = RefreshError(
        message: _friendlyError(error),
        occurredAt: DateTime.now(),
      );
      await prefs.setString(_lastErrorMessageKey, refreshError.message);
      await prefs.setString(
        _lastErrorAtKey,
        refreshError.occurredAt.toUtc().toIso8601String(),
      );
      await _widgetSync.updateWithError(refreshError.message);
      return RefreshResult(
        snapshot: await loadCachedSnapshot(),
        error: refreshError,
      );
    }
  }

  Future<void> updateWidgetFromCache() async {
    final snapshot = await loadCachedSnapshot();
    if (snapshot != null) {
      await _widgetSync.updateWithSnapshot(snapshot);
    }
  }

  String _friendlyError(Object error) {
    if (error is PetrolimexPriceException) {
      return error.message;
    }
    return 'Không thể cập nhật dữ liệu lúc này';
  }
}

class RefreshResult {
  const RefreshResult({this.snapshot, this.error});

  final FuelPriceSnapshot? snapshot;
  final RefreshError? error;
}

class RefreshError {
  const RefreshError({required this.message, required this.occurredAt});

  final String message;
  final DateTime occurredAt;
}
