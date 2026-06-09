import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oil_price_tracking/src/data/fuel_price_repository.dart';
import 'package:oil_price_tracking/src/data/petrolimex_price_service.dart';
import 'package:oil_price_tracking/src/data/widget_data_sync.dart';
import 'package:oil_price_tracking/src/models/fuel_price.dart';
import 'package:oil_price_tracking/src/models/fuel_price_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PetrolimexPriceService', () {
    test('maps API response and sorts products by display order', () {
      final snapshot = PetrolimexPriceService().parseResponse(_apiResponse);

      expect(snapshot.products, hasLength(6));
      expect(snapshot.products.first.title, 'Xang RON 95-V');
      expect(snapshot.products.map((item) => item.orderIndex), [
        1,
        2,
        3,
        4,
        5,
        8,
      ]);
      expect(snapshot.products.first.zone1Price, 20960);
      expect(snapshot.products.first.zone2Price, 21370);
      expect(
        snapshot.updatedAt.toUtc().toIso8601String(),
        '2026-06-04T07:56:28.241Z',
      );
    });
  });

  group('FuelPriceRepository', () {
    test('keeps cached snapshot when refresh fails', () async {
      final cachedSnapshot = FuelPriceSnapshot(
        updatedAt: DateTime.parse('2026-06-04T07:56:28.241Z'),
        products: [
          FuelPrice(
            id: 'cached',
            title: 'Cached product',
            englishTitle: 'Cached product',
            zone1Price: 1000,
            zone2Price: 2000,
            orderIndex: 1,
            lastModified: DateTime.parse('2026-06-04T07:56:28.241Z'),
            link: '',
          ),
        ],
      );
      SharedPreferences.setMockInitialValues({
        'fuel_price_snapshot': jsonEncode(cachedSnapshot.toJson()),
      });

      final repository = FuelPriceRepository(
        service: _FailingPriceService(),
        widgetSync: _NoopWidgetDataSync(),
      );

      final result = await repository.refresh();

      expect(result.snapshot, isNotNull);
      expect(result.snapshot!.products.single.title, 'Cached product');
      expect(result.error, isNotNull);
      expect(result.error!.message, 'API unavailable');
    });
  });

  group('WidgetDataSync', () {
    test('builds up to four widget rows and handles empty snapshot', () {
      final sync = WidgetDataSync();
      final rows = sync.buildRows(
        FuelPriceSnapshot(
          updatedAt: DateTime.parse('2026-06-04T07:56:28.241Z'),
          products: List.generate(
            5,
            (index) => FuelPrice(
              id: '$index',
              title: 'Product $index',
              englishTitle: 'Product $index',
              zone1Price: 10000 + index,
              zone2Price: 20000 + index,
              orderIndex: index,
              lastModified: DateTime.parse('2026-06-04T07:56:28.241Z'),
              link: '',
            ),
          ),
        ),
      );

      expect(rows, hasLength(4));
      expect(rows.first.name, 'Product 0');
      expect(rows.first.price, '10.000 / 20.000');

      final emptyRows = sync.buildRows(
        FuelPriceSnapshot(
          updatedAt: DateTime.parse('2026-06-04T07:56:28.241Z'),
          products: const [],
        ),
      );
      expect(emptyRows, isEmpty);
    });
  });
}

class _FailingPriceService extends PetrolimexPriceService {
  @override
  Future<FuelPriceSnapshot> fetchPrices() {
    throw const PetrolimexPriceException('API unavailable');
  }
}

class _NoopWidgetDataSync extends WidgetDataSync {
  @override
  Future<void> updateWithSnapshot(FuelPriceSnapshot snapshot) async {}

  @override
  Future<void> updateWithError(String message) async {}
}

final _apiResponse = {
  'Objects': [
    {
      'ID': 'ko',
      'Title': 'Dau hoa 2-K',
      'EnglishTitle': '2-K Kerosene',
      'Zone1Price': 24960,
      'Zone2Price': 25450,
      'DIsplayOrder': 8,
      'LastModified': '2026-06-04T07:56:28.241Z',
      'Link': '',
    },
    {
      'ID': 'ron95v',
      'Title': 'Xang RON 95-V',
      'EnglishTitle': 'RON 95-V',
      'Zone1Price': 20960,
      'Zone2Price': 21370,
      'DIsplayOrder': 1,
      'LastModified': '2026-06-04T07:56:28.241Z',
      'Link': '',
    },
    {
      'ID': 'ron95iii',
      'Title': 'Xang RON 95-III',
      'EnglishTitle': 'RON 95-III',
      'Zone1Price': 20430,
      'Zone2Price': 20830,
      'DIsplayOrder': 2,
      'LastModified': '2026-06-04T07:56:28.241Z',
      'Link': '',
    },
    {
      'ID': 'e5',
      'Title': 'Xang E5 RON 92-II',
      'EnglishTitle': 'E5 RON 92-II',
      'Zone1Price': 19940,
      'Zone2Price': 20330,
      'DIsplayOrder': 3,
      'LastModified': '2026-06-04T07:56:28.241Z',
      'Link': '',
    },
    {
      'ID': 'diesel',
      'Title': 'Diezen 0,05S',
      'EnglishTitle': 'Diesel 0.05S',
      'Zone1Price': 17910,
      'Zone2Price': 18260,
      'DIsplayOrder': 4,
      'LastModified': '2026-06-04T07:56:28.241Z',
      'Link': '',
    },
    {
      'ID': 'mazut',
      'Title': 'Mazut 180CST 3,5S',
      'EnglishTitle': 'Fuel oil 180CST 3.5S',
      'Zone1Price': 15390,
      'Zone2Price': 15690,
      'DIsplayOrder': 5,
      'LastModified': '2026-06-04T07:56:28.241Z',
      'Link': '',
    },
  ],
};
