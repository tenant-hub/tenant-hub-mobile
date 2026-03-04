import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/core/storage/secure_storage_service.dart';
import 'package:tenant_hub_mobile/core/utils/jwt_utils.dart';
import 'package:tenant_hub_mobile/features/auth/domain/auth_user.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository({required Dio dio, required SecureStorageService storage})
      : _dio = dio,
        _storage = storage;

  Future<AuthUser> login(String username, String password) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'username': username,
        'password': password,
      });
      final accessToken = response.data['accessToken'] as String;
      await _storage.setToken(accessToken);
      return JwtUtils.parseUser(accessToken);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {
      // Sessizce devam et
    } finally {
      await _storage.clearToken();
    }
  }

  Future<AuthUser?> getCurrentUser() async {
    final token = await _storage.getToken();
    if (token == null) return null;
    try {
      if (JwtUtils.isExpired(token)) return null;
      return JwtUtils.parseUser(token);
    } catch (_) {
      return null;
    }
  }
}
