class CalculationResult {
  final double totalAssets;
  final double totalDebts;
  final double netZakatableAmount;
  final double nisabThreshold;
  final bool isNisabReached;
  final double zakatToPay;
  final double goldRate;
  final double conversionRate;

  CalculationResult({
    required this.totalAssets,
    required this.totalDebts,
    required this.netZakatableAmount,
    required this.nisabThreshold,
    required this.isNisabReached,
    required this.zakatToPay,
    required this.goldRate,
    required this.conversionRate,
  });

  factory CalculationResult.empty() {
    return CalculationResult(
      totalAssets: 0,
      totalDebts: 0,
      netZakatableAmount: 0,
      nisabThreshold: 0,
      isNisabReached: false,
      zakatToPay: 0,
      goldRate: 0,
      conversionRate: 1.0,
    );
  }
}

