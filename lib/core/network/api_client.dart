import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.defaultApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.keyAuthToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final customUrl = prefs.getString(AppConstants.keyApiUrl);
          if (customUrl != null && customUrl.isNotEmpty) {
            options.baseUrl = customUrl;
          } else {
            options.baseUrl = AppConstants.defaultApiBaseUrl;
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint('🌐 [Student API Error] ${e.requestOptions.method} ${e.requestOptions.path} -> ${e.response?.statusCode}: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }
}
