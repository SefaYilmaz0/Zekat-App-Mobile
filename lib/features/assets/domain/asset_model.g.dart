// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetModelAdapter extends TypeAdapter<AssetModel> {
  @override
  final int typeId = 1;

  @override
  AssetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as AssetCategory,
      value: fields[3] as double,
      previousValue: fields[4] as double?,
      description: fields[5] as String?,
      details: (fields[6] as Map?)?.cast<dynamic, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AssetModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.previousValue)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.details);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AssetCategoryAdapter extends TypeAdapter<AssetCategory> {
  @override
  final int typeId = 0;

  @override
  AssetCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AssetCategory.gold;
      case 1:
        return AssetCategory.cash;
      case 2:
        return AssetCategory.livestock;
      case 3:
        return AssetCategory.agriculture;
      case 4:
        return AssetCategory.receivable;
      case 5:
        return AssetCategory.debt;
      default:
        return AssetCategory.gold;
    }
  }

  @override
  void write(BinaryWriter writer, AssetCategory obj) {
    switch (obj) {
      case AssetCategory.gold:
        writer.writeByte(0);
        break;
      case AssetCategory.cash:
        writer.writeByte(1);
        break;
      case AssetCategory.livestock:
        writer.writeByte(2);
        break;
      case AssetCategory.agriculture:
        writer.writeByte(3);
        break;
      case AssetCategory.receivable:
        writer.writeByte(4);
        break;
      case AssetCategory.debt:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
