import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/permissions/domain/permission_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

class PermissionRepository {
  final Dio _dio;

  PermissionRepository({required Dio dio}) : _dio = dio;

  Future<PageResponse<Permission>> getPermissions({
    int page = 0,
    int size = 10,
    String? sort,
    String? name,
    String? module,
    String? action,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (sort != null) params['sort'] = sort;
      if (name != null && name.isNotEmpty) params['name'] = name;
      if (module != null && module.isNotEmpty) params['module'] = module;
      if (action != null && action.isNotEmpty) params['action'] = action;
      if (status != null && status.isNotEmpty) params['status'] = status;

      final response =
          await _dio.get(ApiConstants.permissions, queryParameters: params);
      return PageResponse.fromJson(response.data, Permission.fromJson);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Permission> createPermission(PermissionRequest request) async {
    try {
      final response =
          await _dio.post(ApiConstants.permissions, data: request.toJson());
      return Permission.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Permission> updatePermission(int id, PermissionRequest request) async {
    try {
      final response = await _dio.put('${ApiConstants.permissions}/$id',
          data: request.toJson());
      return Permission.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> deletePermission(int id) async {
    try {
      await _dio.delete('${ApiConstants.permissions}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
