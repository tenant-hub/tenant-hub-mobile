import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/core/storage/secure_storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient.create(storage);
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class DioClient {
  DioClient._();

  static Dio create(SecureStorageService storage) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Cookie manager for httpOnly refresh token
    final cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));

    // Auth interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.extra.containsKey('_retry')) {
          error.requestOptions.extra['_retry'] = true;
          try {
            // Refresh token is sent automatically via cookie
            final refreshDio = Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              contentType: 'application/json',
            ));
            refreshDio.interceptors.add(CookieManager(cookieJar));

            final response = await refreshDio.post(ApiConstants.refresh);
            final newToken = response.data['accessToken'] as String;
            await storage.setToken(newToken);

            // Retry original request
            error.requestOptions.headers['Authorization'] =
                'Bearer $newToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            await storage.clearToken();
            return handler.reject(error);
          }
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  static ApiException handleError(DioException e) {
    final message =
        e.response?.data is Map ? e.response?.data['message'] : null;
    return ApiException(
      message: message ?? 'Bir hata oluştu',
      statusCode: e.response?.statusCode,
    );
  }
}
