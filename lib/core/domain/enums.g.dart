// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LanguageAdapter extends TypeAdapter<Language> {
  @override
  final int typeId = 2;

  @override
  Language read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Language.tr;
      case 1:
        return Language.en;
      default:
        return Language.tr;
    }
  }

  @override
  void write(BinaryWriter writer, Language obj) {
    switch (obj) {
      case Language.tr:
        writer.writeByte(0);
        break;
      case Language.en:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SectAdapter extends TypeAdapter<Sect> {
  @override
  final int typeId = 3;

  @override
  Sect read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Sect.hanefi;
      case 1:
        return Sect.safi;
      case 2:
        return Sect.maliki;
      case 3:
        return Sect.hanbeli;
      default:
        return Sect.hanefi;
    }
  }

  @override
  void write(BinaryWriter writer, Sect obj) {
    switch (obj) {
      case Sect.hanefi:
        writer.writeByte(0);
        break;
      case Sect.safi:
        writer.writeByte(1);
        break;
      case Sect.maliki:
        writer.writeByte(2);
        break;
      case Sect.hanbeli:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppCurrencyAdapter extends TypeAdapter<AppCurrency> {
  @override
  final int typeId = 4;

  @override
  AppCurrency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppCurrency.tryCurrency;
      case 1:
        return AppCurrency.usd;
      case 2:
        return AppCurrency.eur;
      default:
        return AppCurrency.tryCurrency;
    }
  }

  @override
  void write(BinaryWriter writer, AppCurrency obj) {
    switch (obj) {
      case AppCurrency.tryCurrency:
        writer.writeByte(0);
        break;
      case AppCurrency.usd:
        writer.writeByte(1);
        break;
      case AppCurrency.eur:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCurrencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

