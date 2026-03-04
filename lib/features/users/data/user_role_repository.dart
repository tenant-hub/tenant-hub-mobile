import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_role_model.dart';

class UserRoleRepository {
  final Dio _dio;

  UserRoleRepository({required Dio dio}) : _dio = dio;

  Future<List<UserRoleResponse>> getRolesByUserId(int userId) async {
    try {
      final response =
          await _dio.get('${ApiConstants.userRoles}/user/$userId');
      return (response.data as List)
          .map((e) => UserRoleResponse.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<UserRoleResponse> assignRoleToUser(UserRoleRequest request) async {
    try {
      final response =
          await _dio.post(ApiConstants.userRoles, data: request.toJson());
      return UserRoleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> removeUserRole(int id) async {
    try {
      await _dio.delete('${ApiConstants.userRoles}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
