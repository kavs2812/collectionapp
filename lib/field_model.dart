import 'package:hive/hive.dart';

part 'field_model.g.dart';

@HiveType(typeId: 0)
class FieldModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final bool isMandatory;

  @HiveField(3)
  final bool isDefault;

  FieldModel({
    required this.name,
    required this.type,
    this.isMandatory = false,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'isMandatory': isMandatory,
      'isDefault': isDefault,
    };
  }

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      name: json['name'],
      type: json['type'],
      isMandatory: json['isMandatory'] ?? false,
      isDefault: json['isDefault'] ?? false,
    );
  }
}
