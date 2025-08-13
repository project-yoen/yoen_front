import 'package:dio/dio.dart';

class ApiCountInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    ApiCallLogger.logRequest(options);
    super.onRequest(options, handler);
  }
}

class ApiCallLogger {
  static int totalCalls = 0;

  static void logRequest(RequestOptions options) {
    totalCalls++;
    print('[API CALL #$totalCalls] ${options.method} ${options.uri}');
  }
}
