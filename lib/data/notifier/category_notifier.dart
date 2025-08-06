import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/category_response.dart';
import 'package:yoen_front/data/repository/category_repository.dart';

final categoryProvider = FutureProvider.family<List<Category>, String>((
  ref,
  type,
) async {
  final repository = ref.read(categoryRepositoryProvider);
  return await repository.getCategories(type);
});
