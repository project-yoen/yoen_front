import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifier/login_notifier.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Dio dio;
  int _failCount = 0;

  AuthInterceptor(this.ref, this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'accessToken');

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // access token이 만료되었을 경우

    if (err.response?.statusCode == 403 && !_isRetry(err.requestOptions)) {
      final storage = ref.read(secureStorageProvider);
      final accessToken = await storage.read(key: 'accessToken');
      final refreshToken = await storage.read(key: 'refreshToken');
      // 여기서 실패 카운트 누적

      _failCount++;
      if (_failCount >= 5) {
        await storage.deleteAll();
        _failCount = 0; // 초기화
      }

      if (refreshToken != null) {
        try {
          final response = await dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['data']['accessToken'];
          final newRefreshToken = response.data['data']['refreshToken'];

          await storage.write(key: 'accessToken', value: newAccessToken);
          await storage.write(key: 'refreshToken', value: newRefreshToken);

          final requestOptions = err.requestOptions;

          // 재시도 플래그 설정
          requestOptions.extra['retried'] = true;

          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final clonedResponse = await dio.request(
            requestOptions.path,
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
            ),
          );

          return handler.resolve(clonedResponse);
        } catch (_) {
          // 리프레시 토큰 만료 등으로 재발급 실패 시, 로그아웃 처리
          await storage.deleteAll();
          // await ref.read(loginNotifierProvider.notifier).logout();
          // 에러를 다시 던지는 대신, 여기서 인터셉터 체인을 중단하여
          // 앱이 멈추는 것을 방지하고 로그인 화면으로 이동하도록 합니다.
          return;
        }
      }
    }

    return handler.next(err);
  }

  bool _isRetry(RequestOptions options) {
    return options.extra['retried'] == true;
  }
}
