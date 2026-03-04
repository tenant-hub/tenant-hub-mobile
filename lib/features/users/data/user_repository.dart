import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

class UserRepository {
  final Dio _dio;

  UserRepository({required Dio dio}) : _dio = dio;

  Future<PageResponse<User>> getUsers({
    int page = 0,
    int size = 10,
    String? sort,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (sort != null) params['sort'] = sort;
      if (username != null && username.isNotEmpty) params['username'] = username;
      if (email != null && email.isNotEmpty) params['email'] = email;
      if (firstName != null && firstName.isNotEmpty) params['firstName'] = firstName;
      if (lastName != null && lastName.isNotEmpty) params['lastName'] = lastName;
      if (status != null && status.isNotEmpty) params['status'] = status;

      final response = await _dio.get(ApiConstants.users, queryParameters: params);
      return PageResponse.fromJson(response.data, User.fromJson);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<User> createUser(CreateUserRequest request) async {
    try {
      final response = await _dio.post(ApiConstants.users, data: request.toJson());
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<User> updateUser(int id, UpdateUserRequest request) async {
    try {
      final response =
          await _dio.put('${ApiConstants.users}/$id', data: request.toJson());
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('${ApiConstants.users}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
