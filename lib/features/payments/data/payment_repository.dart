import 'package:dio/dio.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/payments/domain/payment_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

class PaymentRepository {
  final Dio _dio;

  PaymentRepository({required Dio dio}) : _dio = dio;

  Future<PageResponse<Payment>> getPayments({
    int page = 0,
    int size = 10,
    String? sort,
    String? status,
    int? rentId,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (sort != null) params['sort'] = sort;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (rentId != null) params['rentId'] = rentId;

      final response =
          await _dio.get(ApiConstants.payments, queryParameters: params);
      return PageResponse.fromJson(response.data, Payment.fromJson);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Payment> createPayment(PaymentRequest request) async {
    try {
      final response =
          await _dio.post(ApiConstants.payments, data: request.toJson());
      return Payment.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<Payment> updatePayment(int id, PaymentRequest request) async {
    try {
      final response = await _dio.put('${ApiConstants.payments}/$id',
          data: request.toJson());
      return Payment.fromJson(response.data);
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> updatePaymentStatus(int id, String status) async {
    try {
      await _dio.patch('${ApiConstants.payments}/$id/status/$status');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }

  Future<void> deletePayment(int id) async {
    try {
      await _dio.delete('${ApiConstants.payments}/$id');
    } on DioException catch (e) {
      throw DioClient.handleError(e);
    }
  }
}
