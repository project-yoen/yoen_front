import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiClient.apiService;
});
