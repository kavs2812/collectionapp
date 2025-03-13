import 'package:hive/hive.dart';

part 'field_model.g.dart';

@HiveType(typeId: 0)
class FieldModel {
  @HiveField(0)
  String name;

  @HiveField(1)
  String type;

  @HiveField(2)
  bool isMandatory;

  @HiveField(3)
  List<String> options; // New field for dropdown options

  FieldModel({
    required this.name,
    required this.type,
    this.isMandatory = false,
    this.options = const [],
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      name: json['name'],
      type: json['type'],
      isMandatory: json['isMandatory'] ?? false,
      options: (json['options'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'isMandatory': isMandatory,
      'options': options,
    };
  }
}
