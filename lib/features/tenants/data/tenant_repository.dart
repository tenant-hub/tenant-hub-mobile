import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/tenants/domain/tenant_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

class TenantRepository {
  final Dio _dio;

  TenantRepository({required Dio dio}) : _dio = dio;

  Future<PageResponse<Tenant>> getTenants({
    int page = 0,
    int size = 10,
    String? sort,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (sort != null) params['sort'] = sort;

      final response =
          await _dio.get(ApiConstants.tenants, queryParameters: params);
      return PageResponse.fromJson(response.data, Tenant.fromJson);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Tenant> createTenant(TenantRequest request) async {
    try {
      final response =
          await _dio.post(ApiConstants.tenants, data: request.toJson());
      return Tenant.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Tenant> updateTenant(int id, TenantRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.tenants}/$id',
        data: request.toJson(),
      );
      return Tenant.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> deleteTenant(int id) async {
    try {
      await _dio.delete('${ApiConstants.tenants}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
