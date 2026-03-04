import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/rents/data/rent_repository.dart';
import 'package:tenant_hub_mobile/features/rents/domain/rent_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

final rentRepositoryProvider = Provider<RentRepository>((ref) {
  return RentRepository(dio: ref.watch(dioProvider));
});

final rentsProvider =
    StateNotifierProvider<RentsNotifier, AsyncValue<PageResponse<Rent>>>((ref) {
  return RentsNotifier(ref.watch(rentRepositoryProvider));
});

class RentsNotifier extends StateNotifier<AsyncValue<PageResponse<Rent>>> {
  final RentRepository _repository;
  int _page = 0;
  final int _size = 10;
  Map<String, String> _filters = {};

  RentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchRents();
  }

  Future<void> fetchRents() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getRents(
        page: _page,
        size: _size,
        sort: 'rentDate,desc',
        status: _filters['status'],
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPage(int page) async {
    _page = page;
    await fetchRents();
  }

  Future<void> setFilters(Map<String, String> filters) async {
    _filters = filters;
    _page = 0;
    await fetchRents();
  }

  Future<void> clearFilters() async {
    _filters = {};
    _page = 0;
    await fetchRents();
  }

  Future<void> createRent(RentRequest request) async {
    await _repository.createRent(request);
    await fetchRents();
  }

  Future<void> updateRent(int id, RentRequest request) async {
    await _repository.updateRent(id, request);
    await fetchRents();
  }

  Future<void> updateRentStatus(int id, String status) async {
    await _repository.updateRentStatus(id, status);
    await fetchRents();
  }

  Future<void> deleteRent(int id) async {
    await _repository.deleteRent(id);
    await fetchRents();
  }
}
