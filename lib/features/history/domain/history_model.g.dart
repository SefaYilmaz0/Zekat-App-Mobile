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
      hijriDate: fields[10] as String?,
      totalAssets: fields[11] as double?,
      totalDebts: fields[12] as double?,
      netZakatableAmount: fields[13] as double?,
      nisabThreshold: fields[14] as double?,
      paymentMethod: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryModel obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.liabilities)
      ..writeByte(10)
      ..write(obj.hijriDate)
      ..writeByte(11)
      ..write(obj.totalAssets)
      ..writeByte(12)
      ..write(obj.totalDebts)
      ..writeByte(13)
      ..write(obj.netZakatableAmount)
      ..writeByte(14)
      ..write(obj.nisabThreshold)
      ..writeByte(15)
      ..write(obj.paymentMethod);
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
