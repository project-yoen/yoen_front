import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/category_response.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CategoryRepository(apiService);
});

class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository(this._apiService);

  Future<List<Category>> getCategories(String type) async {
    final response = await _apiService.getCategories(type);
    return response.data!;
  }
}
