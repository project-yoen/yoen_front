import 'package:json_annotation/json_annotation.dart';

part 'category_response.g.dart';

@JsonSerializable()
class Category {
  final int categoryId;
  final String categoryName;
  final String type;

  Category({
    required this.categoryId,
    required this.categoryName,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}