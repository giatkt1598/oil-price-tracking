import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/fuel_price_snapshot.dart';

class WidgetDataSync {
  const WidgetDataSync();

  static const androidProviderName =
      'com.example.oil_price_tracking.FuelPriceWidgetProvider';

  List<WidgetPriceRow> buildRows(FuelPriceSnapshot snapshot) {
    final currencyFormat = NumberFormat.decimalPattern('vi_VN');
    return snapshot.products
        .take(4)
        .map(
          (product) => WidgetPriceRow(
            name: product.title,
            price:
                '${currencyFormat.format(product.zone1Price)} / ${currencyFormat.format(product.zone2Price)}',
          ),
        )
        .toList();
  }

  Future<void> updateWithSnapshot(FuelPriceSnapshot snapshot) async {
    final timeFormat = DateFormat('HH:mm dd/MM', 'vi_VN');
    final rows = buildRows(snapshot);

    await HomeWidget.saveWidgetData<String>('widget_title', 'Petrolimex');
    await HomeWidget.saveWidgetData<String>(
      'widget_updated_at',
      'Cap nhat ${timeFormat.format(snapshot.displayUpdatedAt.toLocal())}',
    );
    await HomeWidget.saveWidgetData<String>('widget_error', '');
    await HomeWidget.saveWidgetData<int>('widget_count', rows.length);

    for (var i = 0; i < 4; i++) {
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

  Future<void> updateWithError(String message) async {
    await HomeWidget.saveWidgetData<String>('widget_error', message);
    await HomeWidget.updateWidget(qualifiedAndroidName: androidProviderName);
  }
}

class WidgetPriceRow {
  const WidgetPriceRow({required this.name, required this.price});

  final String name;
  final String price;
}
