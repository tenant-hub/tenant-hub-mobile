import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/real_estates/domain/real_estate_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

class RealEstateRepository {
  final Dio _dio;

  RealEstateRepository({required Dio dio}) : _dio = dio;

  Future<PageResponse<RealEstate>> getRealEstates({
    int page = 0,
    int size = 10,
    String? sort,
    String? name,
    String? type,
    String? province,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (sort != null) params['sort'] = sort;
      if (name != null && name.isNotEmpty) params['name'] = name;
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (province != null && province.isNotEmpty) params['province'] = province;
      if (status != null && status.isNotEmpty) params['status'] = status;

      final response =
          await _dio.get(ApiConstants.realEstates, queryParameters: params);
      return PageResponse.fromJson(response.data, RealEstate.fromJson);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<RealEstate> createRealEstate(RealEstateRequest request) async {
    try {
      final response =
          await _dio.post(ApiConstants.realEstates, data: request.toJson());
      return RealEstate.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<RealEstate> updateRealEstate(int id, RealEstateRequest request) async {
    try {
      final response = await _dio.put('${ApiConstants.realEstates}/$id',
          data: request.toJson());
      return RealEstate.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> deleteRealEstate(int id) async {
    try {
      await _dio.delete('${ApiConstants.realEstates}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
