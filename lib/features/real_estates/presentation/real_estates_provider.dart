import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/real_estates/data/real_estate_repository.dart';
import 'package:tenant_hub_mobile/features/real_estates/domain/real_estate_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

final realEstateRepositoryProvider = Provider<RealEstateRepository>((ref) {
  return RealEstateRepository(dio: ref.watch(dioProvider));
});

final realEstatesProvider =
    StateNotifierProvider<RealEstatesNotifier, AsyncValue<PageResponse<RealEstate>>>((ref) {
  return RealEstatesNotifier(ref.watch(realEstateRepositoryProvider));
});

class RealEstatesNotifier extends StateNotifier<AsyncValue<PageResponse<RealEstate>>> {
  final RealEstateRepository _repository;
  int _page = 0;
  final int _size = 10;
  Map<String, String> _filters = {};

  RealEstatesNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchRealEstates();
  }

  Future<void> fetchRealEstates() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getRealEstates(
        page: _page,
        size: _size,
        sort: 'name,asc',
        name: _filters['name'],
        type: _filters['type'],
        province: _filters['province'],
        status: _filters['status'],
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPage(int page) async {
    _page = page;
    await fetchRealEstates();
  }

  Future<void> setFilters(Map<String, String> filters) async {
    _filters = filters;
    _page = 0;
    await fetchRealEstates();
  }

  Future<void> clearFilters() async {
    _filters = {};
    _page = 0;
    await fetchRealEstates();
  }

  Future<void> createRealEstate(RealEstateRequest request) async {
    await _repository.createRealEstate(request);
    await fetchRealEstates();
  }

  Future<void> updateRealEstate(int id, RealEstateRequest request) async {
    await _repository.updateRealEstate(id, request);
    await fetchRealEstates();
  }

  Future<void> deleteRealEstate(int id) async {
    await _repository.deleteRealEstate(id);
    await fetchRealEstates();
  }
}
