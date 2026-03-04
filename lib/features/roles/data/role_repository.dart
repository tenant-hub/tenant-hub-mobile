import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/roles/domain/role_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

class RoleRepository {
  final Dio _dio;

  RoleRepository({required Dio dio}) : _dio = dio;

  Future<PageResponse<Role>> getRoles({
    int page = 0,
    int size = 10,
    String? sort,
    String? name,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (sort != null) params['sort'] = sort;
      if (name != null && name.isNotEmpty) params['name'] = name;
      if (status != null && status.isNotEmpty) params['status'] = status;

      final response = await _dio.get(ApiConstants.roles, queryParameters: params);
      return PageResponse.fromJson(response.data, Role.fromJson);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Role> createRole(RoleRequest request) async {
    try {
      final response = await _dio.post(ApiConstants.roles, data: request.toJson());
      return Role.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Role> updateRole(int id, RoleRequest request) async {
    try {
      final response =
          await _dio.put('${ApiConstants.roles}/$id', data: request.toJson());
      return Role.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> deleteRole(int id) async {
    try {
      await _dio.delete('${ApiConstants.roles}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
