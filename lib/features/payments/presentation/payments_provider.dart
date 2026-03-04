import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/payments/data/payment_repository.dart';
import 'package:tenant_hub_mobile/features/payments/domain/payment_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(dio: ref.watch(dioProvider));
});

final paymentsProvider =
    StateNotifierProvider<PaymentsNotifier, AsyncValue<PageResponse<Payment>>>((ref) {
  return PaymentsNotifier(ref.watch(paymentRepositoryProvider));
});

class PaymentsNotifier extends StateNotifier<AsyncValue<PageResponse<Payment>>> {
  final PaymentRepository _repository;
  int _page = 0;
  final int _size = 10;
  Map<String, String> _filters = {};

  PaymentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getPayments(
        page: _page,
        size: _size,
        sort: 'paymentDate,desc',
        status: _filters['status'],
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPage(int page) async {
    _page = page;
    await fetchPayments();
  }

  Future<void> setFilters(Map<String, String> filters) async {
    _filters = filters;
    _page = 0;
    await fetchPayments();
  }

  Future<void> clearFilters() async {
    _filters = {};
    _page = 0;
    await fetchPayments();
  }

  Future<void> createPayment(PaymentRequest request) async {
    await _repository.createPayment(request);
    await fetchPayments();
  }

  Future<void> updatePayment(int id, PaymentRequest request) async {
    await _repository.updatePayment(id, request);
    await fetchPayments();
  }

  Future<void> updatePaymentStatus(int id, String status) async {
    await _repository.updatePaymentStatus(id, status);
    await fetchPayments();
  }

  Future<void> deletePayment(int id) async {
    await _repository.deletePayment(id);
    await fetchPayments();
  }
}
