// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FieldModelAdapter extends TypeAdapter<FieldModel> {
  @override
  final int typeId = 0;

  @override
  FieldModel read(BinaryReader reader) {
    return FieldModel(
      name: reader.readString(),
      type: reader.readString(),
      isMandatory: reader.readBool(),
      isDefault: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, FieldModel obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.type);
    writer.writeBool(obj.isMandatory);
    writer.writeBool(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
