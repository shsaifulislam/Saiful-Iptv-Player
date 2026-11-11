import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';

class ApiClient {
  ApiClient(AppConfig config)
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: config.apiTimeout,
            receiveTimeout: config.apiTimeout,
            sendTimeout: config.apiTimeout,
            headers: const {'Accept': 'application/json'},
          ),
        );

  final Dio _dio;

  Dio get dio => _dio;
}
