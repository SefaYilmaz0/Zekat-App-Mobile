// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExchangeRateModelAdapter extends TypeAdapter<ExchangeRateModel> {
  @override
  final int typeId = 8;

  @override
  ExchangeRateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeRateModel(
      currencyCode: fields[0] as String,
      currencyName: fields[1] as String,
      buyingPrice: fields[2] as double,
      sellingPrice: fields[3] as double,
      lastUpdate: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeRateModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.currencyCode)
      ..writeByte(1)
      ..write(obj.currencyName)
      ..writeByte(2)
      ..write(obj.buyingPrice)
      ..writeByte(3)
      ..write(obj.sellingPrice)
      ..writeByte(4)
      ..write(obj.lastUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
