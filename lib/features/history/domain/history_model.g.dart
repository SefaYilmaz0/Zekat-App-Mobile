// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryModelAdapter extends TypeAdapter<HistoryModel> {
  @override
  final int typeId = 6;

  @override
  HistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryModel(
      id: fields[0] as int,
      period: fields[1] as String,
      gregorian: fields[2] as String,
      amount: fields[3] as double,
      currency: fields[4] as String,
      status: fields[5] as String,
      assetCount: fields[6] as int,
      date: fields[7] as String,
      assets: (fields[8] as List).cast<AssetModel>(),
      liabilities: (fields[9] as List).cast<AssetModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.period)
      ..writeByte(2)
      ..write(obj.gregorian)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.assetCount)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.assets)
      ..writeByte(9)
      ..write(obj.liabilities);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

