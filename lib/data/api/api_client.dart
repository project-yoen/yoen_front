import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import 'interceptor/auth_interceptor.dart';

class ApiClient {
  static Dio createDio(Ref ref) {
    final baseUrl = Platform.isAndroid
        ? 'http://10.0.2.2:8080' // Android 에뮬레이터
        : 'http://localhost:8080'; // iOS 시뮬레이터
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
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
