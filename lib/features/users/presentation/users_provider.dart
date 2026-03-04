import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/features/users/data/user_repository.dart';
import 'package:tenant_hub_mobile/features/users/data/user_role_repository.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_model.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_role_model.dart';
import 'package:tenant_hub_mobile/shared/models/page_response.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(dio: ref.watch(dioProvider));
});

final userRoleRepositoryProvider = Provider<UserRoleRepository>((ref) {
  return UserRoleRepository(dio: ref.watch(dioProvider));
});

final usersProvider =
    StateNotifierProvider<UsersNotifier, AsyncValue<PageResponse<User>>>((ref) {
  return UsersNotifier(ref.watch(userRepositoryProvider));
});

class UsersNotifier extends StateNotifier<AsyncValue<PageResponse<User>>> {
  final UserRepository _repository;
  int _page = 0;
  int _size = 10;
  String _sort = 'username,asc';
  Map<String, String> _filters = {};

  UsersNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getUsers(
        page: _page,
        size: _size,
        sort: _sort,
        username: _filters['username'],
        email: _filters['email'],
        firstName: _filters['firstName'],
        lastName: _filters['lastName'],
        status: _filters['status'],
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPage(int page) async {
    _page = page;
    await fetchUsers();
  }

  Future<void> setFilters(Map<String, String> filters) async {
    _filters = filters;
    _page = 0;
    await fetchUsers();
  }

  Future<void> clearFilters() async {
    _filters = {};
    _page = 0;
    await fetchUsers();
  }

  Future<void> createUser(CreateUserRequest request) async {
    await _repository.createUser(request);
    await fetchUsers();
  }

  Future<void> updateUser(int id, UpdateUserRequest request) async {
    await _repository.updateUser(id, request);
    await fetchUsers();
  }

  Future<void> deleteUser(int id) async {
    await _repository.deleteUser(id);
    await fetchUsers();
  }
}

// User roles provider
final userRolesProvider = FutureProvider.family<List<UserRoleResponse>, int>(
  (ref, userId) async {
    final repo = ref.watch(userRoleRepositoryProvider);
    return repo.getRolesByUserId(userId);
  },
);
