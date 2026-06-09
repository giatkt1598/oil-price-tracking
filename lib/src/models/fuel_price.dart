class FuelPrice {
  const FuelPrice({
    required this.id,
    required this.title,
    required this.englishTitle,
    required this.zone1Price,
    required this.zone2Price,
    required this.orderIndex,
    required this.lastModified,
    required this.link,
  });

  final String id;
  final String title;
  final String englishTitle;
  final int zone1Price;
  final int zone2Price;
  final int orderIndex;
  final DateTime lastModified;
  final String link;

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      id: json['ID']?.toString() ?? '',
      title: json['Title']?.toString() ?? '',
      englishTitle: json['EnglishTitle']?.toString() ?? '',
      zone1Price: _toInt(json['Zone1Price']),
      zone2Price: _toInt(json['Zone2Price']),
      orderIndex: _toInt(json['DIsplayOrder'] ?? json['OrderIndex']),
      lastModified:
          DateTime.tryParse(json['LastModified']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      link: json['Link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Title': title,
      'EnglishTitle': englishTitle,
      'Zone1Price': zone1Price,
      'Zone2Price': zone2Price,
      'OrderIndex': orderIndex,
      'LastModified': lastModified.toUtc().toIso8601String(),
      'Link': link,
    };
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
