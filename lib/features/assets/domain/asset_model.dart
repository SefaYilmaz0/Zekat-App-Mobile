import 'package:hive/hive.dart';

part 'asset_model.g.dart';

@HiveType(typeId: 0)
enum AssetType {
  @HiveField(0)
  cash,
  @HiveField(1)
  gold,
  @HiveField(2)
  silver,
  @HiveField(3)
  currency,
}

@HiveType(typeId: 1)
class AssetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  AssetType type;

  @HiveField(3)
  double amount;

  AssetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
  });
}
