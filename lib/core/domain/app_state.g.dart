// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppStateAdapter extends TypeAdapter<AppState> {
  @override
  final int typeId = 5;

  @override
  AppState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppState(
      sect: fields[0] as Sect,
      currency: fields[1] as AppCurrency,
      isDark: fields[2] as bool,
      language: fields[3] as Language,
      onboardingComplete: fields[4] as bool,
      nisabType: fields[5] as NisabType,
    );
  }

  @override
  void write(BinaryWriter writer, AppState obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.sect)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.isDark)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.onboardingComplete)
      ..writeByte(5)
      ..write(obj.nisabType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
