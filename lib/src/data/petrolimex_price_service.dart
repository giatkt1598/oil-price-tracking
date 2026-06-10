import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fuel_price.dart';
import '../models/fuel_price_snapshot.dart';

class PetrolimexPriceService {
  PetrolimexPriceService({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.https(
    'portals.petrolimex.com.vn',
    '/~apis/portals/cms.item/search',
  );

  final http.Client _client;

  Future<FuelPriceSnapshot> fetchPrices() async {
    final uri = _endpoint.replace(
      queryParameters: {
        'x-request': _base64UrlJson(_requestPayload()),
        'x-device-id': 'oil-price-tracking',
        'x-app-name': _base64UrlText('NGX Websites'),
        'x-app-platform': _base64UrlText('Flutter Android'),
        'language': 'vi-VN',
      },
    );

    final response = await _client.get(
      uri,
      headers: const {
        'accept': 'application/json',
        'referer': 'https://www.petrolimex.com.vn/lien-he.html',
      },
    );

    if (response.statusCode != 200) {
      throw PetrolimexPriceException(
        'Petrolimex trả về HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const PetrolimexPriceException('Dữ liệu Petrolimex không hợp lệ');
    }
    return parseResponse(decoded);
  }

  FuelPriceSnapshot parseResponse(Map<String, dynamic> json) {
    final objects = json['Objects'];
    if (objects is! List) {
      throw const PetrolimexPriceException('Không tìm thấy danh sách sản phẩm');
    }

    final products =
        objects
            .whereType<Map<String, dynamic>>()
            .map(FuelPrice.fromJson)
            .where((price) => price.zone1Price > 0 && price.zone2Price > 0)
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (products.isEmpty) {
      throw const PetrolimexPriceException('Bảng giá Petrolimex đang trống');
    }

    final updatedAt = products
        .map((price) => price.lastModified)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return FuelPriceSnapshot(updatedAt: updatedAt, products: products);
  }

  static Map<String, dynamic> _requestPayload() {
    return {
      'FilterBy': {
        'And': [
          {
            'SystemID': {'Equals': '6783dc1271ff449e95b74a9520964169'},
          },
          {
            'RepositoryID': {'Equals': 'a95451e23b474fe5886bfb7cf843f53c'},
          },
          {
            'RepositoryEntityID': {
              'Equals': '3801378fe1e045b1afa10de7c5776124',
            },
          },
          {
            'Status': {'Equals': 'Published'},
          },
        ],
      },
      'SortBy': {'LastModified': 'Descending'},
      'Pagination': {
        'TotalRecords': -1,
        'TotalPages': 0,
        'PageSize': 0,
        'PageNumber': 0,
      },
    };
  }

  static String _base64UrlJson(Map<String, dynamic> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  static String _base64UrlText(String value) {
    return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  }
}

class PetrolimexPriceException implements Exception {
  const PetrolimexPriceException(this.message);

  final String message;

  @override
  String toString() => message;
}
