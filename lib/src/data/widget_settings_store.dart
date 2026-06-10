import 'package:shared_preferences/shared_preferences.dart';

class WidgetSettingsStore {
  const WidgetSettingsStore();

  static const _selectedProductIdsKey = 'widget_selected_product_ids';
  static const _showZone1Key = 'widget_show_zone_1';
  static const _showZone2Key = 'widget_show_zone_2';

  Future<WidgetSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WidgetSettings(
      selectedProductIds:
          prefs.getStringList(_selectedProductIdsKey) ?? const [],
      showZone1: prefs.getBool(_showZone1Key) ?? true,
      showZone2: prefs.getBool(_showZone2Key) ?? true,
    );
  }

  Future<void> save(WidgetSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _selectedProductIdsKey,
      settings.selectedProductIds,
    );
    await prefs.setBool(_showZone1Key, settings.showZone1);
    await prefs.setBool(_showZone2Key, settings.showZone2);
  }
}

class WidgetSettings {
  const WidgetSettings({
    required this.selectedProductIds,
    required this.showZone1,
    required this.showZone2,
  });

  final List<String> selectedProductIds;
  final bool showZone1;
  final bool showZone2;

  WidgetSettings copyWith({
    List<String>? selectedProductIds,
    bool? showZone1,
    bool? showZone2,
  }) {
    return WidgetSettings(
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
      showZone1: showZone1 ?? this.showZone1,
      showZone2: showZone2 ?? this.showZone2,
    );
  }
}
