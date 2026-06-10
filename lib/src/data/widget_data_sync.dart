import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/fuel_price.dart';
import '../models/fuel_price_snapshot.dart';
import 'widget_settings_store.dart';

class WidgetDataSync {
  const WidgetDataSync();

  static const maxWidgetProducts = 6;
  static const androidProviderName =
      'com.example.oil_price_tracking.FuelPriceWidgetProvider';

  Future<void> updateWithSnapshot(FuelPriceSnapshot snapshot) async {
    final settings = await const WidgetSettingsStore().load();
    await updateWithSnapshotAndSettings(snapshot, settings);
  }

  Future<void> updateWithSnapshotAndSettings(
    FuelPriceSnapshot snapshot,
    WidgetSettings settings,
  ) async {
    final timeFormat = DateFormat('HH:mm dd/MM', 'vi_VN');
    final rows = buildRows(snapshot, settings);

    await HomeWidget.saveWidgetData<String>(
      'widget_updated_at',
      'Cập nhật ${timeFormat.format(snapshot.displayUpdatedAt.toLocal())}',
    );
    await HomeWidget.saveWidgetData<String>('widget_error', '');
    await HomeWidget.saveWidgetData<int>('widget_count', rows.length);

    for (var i = 0; i < maxWidgetProducts; i++) {
      if (i < rows.length) {
        final row = rows[i];
        await HomeWidget.saveWidgetData<String>(
          'product_${i + 1}_name',
          row.name,
        );
        await HomeWidget.saveWidgetData<String>(
          'product_${i + 1}_price',
          row.price,
        );
      } else {
        await HomeWidget.saveWidgetData<String>('product_${i + 1}_name', '');
        await HomeWidget.saveWidgetData<String>('product_${i + 1}_price', '');
      }
    }

    await HomeWidget.updateWidget(qualifiedAndroidName: androidProviderName);
  }

  List<WidgetPriceRow> buildRows(
    FuelPriceSnapshot snapshot, [
    WidgetSettings settings = const WidgetSettings(
      selectedProductIds: [],
      showZone1: true,
      showZone2: true,
    ),
  ]) {
    final currencyFormat = NumberFormat.decimalPattern('vi_VN');
    final selectedProducts = _resolveSelectedProducts(snapshot, settings);
    return selectedProducts
        .map(
          (product) => WidgetPriceRow(
            name: product.title,
            price: _formatPrice(product, settings, currencyFormat),
          ),
        )
        .toList();
  }

  Future<void> updateWithError(String message) async {
    await HomeWidget.saveWidgetData<String>('widget_error', message);
    await HomeWidget.updateWidget(qualifiedAndroidName: androidProviderName);
  }

  List<FuelPrice> _resolveSelectedProducts(
    FuelPriceSnapshot snapshot,
    WidgetSettings settings,
  ) {
    if (settings.selectedProductIds.isEmpty) {
      return snapshot.products.take(maxWidgetProducts).toList();
    }
    final selectedIds = settings.selectedProductIds.toSet();
    return snapshot.products
        .where((product) => selectedIds.contains(product.id))
        .take(maxWidgetProducts)
        .toList();
  }

  String _formatPrice(
    FuelPrice product,
    WidgetSettings settings,
    NumberFormat currencyFormat,
  ) {
    final zone1 = currencyFormat.format(product.zone1Price);
    final zone2 = currencyFormat.format(product.zone2Price);
    if (settings.showZone1 && settings.showZone2) {
      return '$zone1 / $zone2';
    }
    if (settings.showZone1) {
      return zone1;
    }
    return zone2;
  }
}

class WidgetPriceRow {
  const WidgetPriceRow({required this.name, required this.price});

  final String name;
  final String price;
}
