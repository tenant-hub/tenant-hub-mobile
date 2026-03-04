import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/permissions/data/permission_repository.dart';
import 'package:tenant_hub_mobile/features/permissions/domain/permission_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  return PermissionRepository(dio: ref.watch(dioProvider));
});

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, AsyncValue<PageResponse<Permission>>>((ref) {
  return PermissionsNotifier(ref.watch(permissionRepositoryProvider));
});

// All permissions for dropdowns
final allPermissionsProvider = FutureProvider<List<Permission>>((ref) async {
  final repo = ref.watch(permissionRepositoryProvider);
  final result = await repo.getPermissions(page: 0, size: 1000);
  return result.content;
});

class PermissionsNotifier extends StateNotifier<AsyncValue<PageResponse<Permission>>> {
  final PermissionRepository _repository;
  int _page = 0;
  final int _size = 10;
  Map<String, String> _filters = {};

  PermissionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchPermissions();
  }

  Future<void> fetchPermissions() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getPermissions(
        page: _page,
        size: _size,
        sort: 'name,asc',
        name: _filters['name'],
        module: _filters['module'],
        action: _filters['action'],
        status: _filters['status'],
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPage(int page) async {
    _page = page;
    await fetchPermissions();
  }

  Future<void> setFilters(Map<String, String> filters) async {
    _filters = filters;
    _page = 0;
    await fetchPermissions();
  }

  Future<void> clearFilters() async {
    _filters = {};
    _page = 0;
    await fetchPermissions();
  }

  Future<void> createPermission(PermissionRequest request) async {
    await _repository.createPermission(request);
    await fetchPermissions();
  }

  Future<void> updatePermission(int id, PermissionRequest request) async {
    await _repository.updatePermission(id, request);
    await fetchPermissions();
  }

  Future<void> deletePermission(int id) async {
    await _repository.deletePermission(id);
    await fetchPermissions();
  }
}
