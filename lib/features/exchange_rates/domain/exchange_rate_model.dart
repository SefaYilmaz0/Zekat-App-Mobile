class ExchangeRateModel {
  final String currencyCode;
  final String currencyName;
  final double buyingPrice;
  final double sellingPrice;
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
