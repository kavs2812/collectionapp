// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CollectionDataAdapter extends TypeAdapter<CollectionData> {
  @override
  final int typeId = 0;

  @override
  CollectionData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollectionData(
      name: fields[0] as String,
      mobileNumber: fields[1] as String,
      occupation: fields[2] as String,
      address: fields[3] as String,
      amount: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CollectionData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.mobileNumber)
      ..writeByte(2)
      ..write(obj.occupation)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
