import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/rents/domain/rent_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

class RentRepository {
  final Dio _dio;

  RentRepository({required Dio dio}) : _dio = dio;

  Future<PageResponse<Rent>> getRents({
    int page = 0,
    int size = 10,
    String? sort,
    String? status,
    int? realEstateId,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (sort != null) params['sort'] = sort;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (realEstateId != null) params['realEstateId'] = realEstateId;

      final response =
          await _dio.get(ApiConstants.rents, queryParameters: params);
      return PageResponse.fromJson(response.data, Rent.fromJson);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Rent> createRent(RentRequest request) async {
    try {
      final response =
          await _dio.post(ApiConstants.rents, data: request.toJson());
      return Rent.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Rent> updateRent(int id, RentRequest request) async {
    try {
      final response =
          await _dio.put('${ApiConstants.rents}/$id', data: request.toJson());
      return Rent.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Rent> updateRentStatus(int id, String status) async {
    try {
      final response =
          await _dio.patch('${ApiConstants.rents}/$id/status/$status');
      return Rent.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> deleteRent(int id) async {
    try {
      await _dio.delete('${ApiConstants.rents}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
