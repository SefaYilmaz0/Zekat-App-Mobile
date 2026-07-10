import 'package:hive_flutter/hive_flutter.dart';

part 'exchange_rate_model.g.dart';

@HiveType(typeId: 8)
class ExchangeRateModel {
  @HiveField(0)
  final String currencyCode;

  @HiveField(1)
  final String currencyName;

  @HiveField(2)
  final double buyingPrice;

  @HiveField(3)
  final double sellingPrice;

  @HiveField(4)
  final DateTime lastUpdate;

  ExchangeRateModel({
    required this.currencyCode,
    required this.currencyName,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.lastUpdate,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json, String code, String name) {
    return ExchangeRateModel(
      currencyCode: code,
      currencyName: name,
      buyingPrice: double.tryParse(json['alis']?.toString() ?? '0') ?? 0.0,
      sellingPrice: double.tryParse(json['satis']?.toString() ?? '0') ?? 0.0,
      lastUpdate: DateTime.now(),
    );
  }
}

