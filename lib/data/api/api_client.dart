import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import 'interceptor/auth_interceptor.dart';

class ApiClient {
  static Dio createDio(Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
      //       BaseOptions(
      //   baseUrl: 'https://99dfaa0c7dfb.ngrok-free.app',
      //   connectTimeout: const Duration(seconds: 10),
      //   receiveTimeout: const Duration(seconds: 10),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'ngrok-skip-browser-warning': 'true',
      //   },
      // ),
    );

    dio.interceptors.add(AuthInterceptor(ref, dio));
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: print, // 로그 출력 방식, 기본은 print
      ),
    );

    return dio;
  }

  static ApiService createApiService(Ref ref) {
    return ApiService(createDio(ref));
  }
}
