import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/tenants/data/tenant_repository.dart';
import 'package:tenant_hub_mobile/features/tenants/domain/tenant_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(dio: ref.watch(dioProvider));
});

final tenantsProvider =
    StateNotifierProvider<TenantsNotifier, AsyncValue<PageResponse<Tenant>>>(
        (ref) {
  return TenantsNotifier(ref.watch(tenantRepositoryProvider));
});

class TenantsNotifier
    extends StateNotifier<AsyncValue<PageResponse<Tenant>>> {
  final TenantRepository _repository;
  int _page = 0;
  final int _size = 10;

  TenantsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchTenants();
  }

  Future<void> fetchTenants() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getTenants(
        page: _page,
        size: _size,
        sort: 'id,asc',
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPage(int page) async {
    _page = page;
    await fetchTenants();
  }

  Future<void> createTenant(TenantRequest request) async {
    await _repository.createTenant(request);
    await fetchTenants();
  }

  Future<void> updateTenant(int id, TenantRequest request) async {
    await _repository.updateTenant(id, request);
    await fetchTenants();
  }

  Future<void> deleteTenant(int id) async {
    await _repository.deleteTenant(id);
    await fetchTenants();
  }
}
