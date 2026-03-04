import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/roles/domain/role_permission_model.dart';

class RolePermissionRepository {
  final Dio _dio;

  RolePermissionRepository({required Dio dio}) : _dio = dio;

  Future<List<RolePermissionResponse>> getPermissionsByRoleId(int roleId) async {
    try {
      final response =
          await _dio.get('${ApiConstants.rolePermissions}/role/$roleId');
      return (response.data as List)
          .map((e) => RolePermissionResponse.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<RolePermissionResponse> assignPermissionToRole(
      RolePermissionRequest request) async {
    try {
      final response =
          await _dio.post(ApiConstants.rolePermissions, data: request.toJson());
      return RolePermissionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> removeRolePermission(int id) async {
    try {
      await _dio.delete('${ApiConstants.rolePermissions}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
