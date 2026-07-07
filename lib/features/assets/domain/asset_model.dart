import 'package:hive/hive.dart';

part 'asset_model.g.dart';

@HiveType(typeId: 0)
enum AssetCategory {
  @HiveField(0)
  gold,
  @HiveField(1)
  cash,
  @HiveField(2)
  livestock,
  @HiveField(3)
  agriculture,
  @HiveField(4)
  receivable,
  @HiveField(5)
  debt,
}

@HiveType(typeId: 1)
class AssetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  AssetCategory category;

  @HiveField(3)
  double value;

  @HiveField(4)
  double? previousValue;

  @HiveField(5)
  String? description;

  @HiveField(6)
  Map<dynamic, dynamic>? details;

  AssetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
    this.previousValue,
    this.description,
    this.details,
  });
}

