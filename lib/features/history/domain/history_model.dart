import 'package:hive/hive.dart';
import '../../assets/domain/asset_model.dart';

part 'history_model.g.dart';

@HiveType(typeId: 6)
class HistoryModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String period;

  @HiveField(2)
  String gregorian;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String currency;

  @HiveField(5)
  String status;

  @HiveField(6)
  int assetCount;

  @HiveField(7)
  String date;

  @HiveField(8)
  List<AssetModel> assets;

  @HiveField(9)
  List<AssetModel> liabilities;

  HistoryModel({
    required this.id,
    required this.period,
    required this.gregorian,
    required this.amount,
    required this.currency,
    required this.status,
    required this.assetCount,
    required this.date,
    required this.assets,
    required this.liabilities,
  });
}

