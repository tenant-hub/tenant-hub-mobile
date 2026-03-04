import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/roles/data/role_permission_repository.dart';
import 'package:tenant_hub_mobile/features/roles/data/role_repository.dart';
import 'package:tenant_hub_mobile/features/roles/domain/role_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepository(dio: ref.watch(dioProvider));
});

final rolePermissionRepositoryProvider = Provider<RolePermissionRepository>((ref) {
  return RolePermissionRepository(dio: ref.watch(dioProvider));
});

final rolesProvider =
    StateNotifierProvider<RolesNotifier, AsyncValue<PageResponse<Role>>>((ref) {
  return RolesNotifier(ref.watch(roleRepositoryProvider));
});

// All roles for dropdowns
final allRolesProvider = FutureProvider<List<Role>>((ref) async {
  final repo = ref.watch(roleRepositoryProvider);
  final result = await repo.getRoles(page: 0, size: 1000);
  return result.content;
});

class RolesNotifier extends StateNotifier<AsyncValue<PageResponse<Role>>> {
  final RoleRepository _repository;
  int _page = 0;
  final int _size = 10;
  String _sort = 'name,asc';
  Map<String, String> _filters = {};

  RolesNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getRoles(
        page: _page,
        size: _size,
        sort: _sort,
        name: _filters['name'],
        status: _filters['status'],
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPage(int page) async {
    _page = page;
    await fetchRoles();
  }

  Future<void> setFilters(Map<String, String> filters) async {
    _filters = filters;
    _page = 0;
    await fetchRoles();
  }

  Future<void> clearFilters() async {
    _filters = {};
    _page = 0;
    await fetchRoles();
  }

  Future<void> createRole(RoleRequest request) async {
    await _repository.createRole(request);
    await fetchRoles();
  }

  Future<void> updateRole(int id, RoleRequest request) async {
    await _repository.updateRole(id, request);
    await fetchRoles();
  }

  Future<void> deleteRole(int id) async {
    await _repository.deleteRole(id);
    await fetchRoles();
  }
}
