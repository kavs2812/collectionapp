import 'package:hive/hive.dart';

part 'collection_model.g.dart'; // Will be generated

@HiveType(typeId: 0)
class CollectionData {
  @HiveField(0)
  String name;

  @HiveField(1)
  String mobileNumber;

  @HiveField(2)
  String occupation;

  @HiveField(3)
  String address;

  @HiveField(4)
  double amount;

  CollectionData({
    required this.name,
    required this.mobileNumber,
    required this.occupation,
    required this.address,
    required this.amount,
  });
}
