import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_model.dart';
import 'package:tenant_hub_mobile/features/users/presentation/user_form_dialog.dart';
import 'package:tenant_hub_mobile/features/users/presentation/user_roles_sheet.dart';
import 'package:tenant_hub_mobile/features/users/presentation/users_provider.dart';
import 'package:tenant_hub_mobile/shared/widgets/confirm_dialog.dart';
import 'package:tenant_hub_mobile/shared/widgets/empty_state_widget.dart';
import 'package:tenant_hub_mobile/shared/widgets/status_chip.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  bool _showFilters = false;
  final _usernameFilter = TextEditingController();
  final _emailFilter = TextEditingController();
  final _firstNameFilter = TextEditingController();
  final _lastNameFilter = TextEditingController();
  String? _statusFilter;

  @override
  void dispose() {
    _usernameFilter.dispose();
    _emailFilter.dispose();
    _firstNameFilter.dispose();
    _lastNameFilter.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = <String, String>{};
    if (_usernameFilter.text.isNotEmpty) filters['username'] = _usernameFilter.text;
    if (_emailFilter.text.isNotEmpty) filters['email'] = _emailFilter.text;
    if (_firstNameFilter.text.isNotEmpty) filters['firstName'] = _firstNameFilter.text;
    if (_lastNameFilter.text.isNotEmpty) filters['lastName'] = _lastNameFilter.text;
    if (_statusFilter != null) filters['status'] = _statusFilter!;
    ref.read(usersProvider.notifier).setFilters(filters);
  }

  void _clearFilters() {
    _usernameFilter.clear();
    _emailFilter.clear();
    _firstNameFilter.clear();
    _lastNameFilter.clear();
    setState(() => _statusFilter = null);
    ref.read(usersProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final canCreate = authNotifier.hasPermission(PermissionKeys.userCreate);
    final canUpdate = authNotifier.hasPermission(PermissionKeys.userUpdate);
    final canDelete = authNotifier.hasPermission(PermissionKeys.userDelete);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kullanıcılar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                  ),
                  if (canCreate)
                    FilledButton.icon(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Yeni'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Filters
        if (_showFilters)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usernameFilter,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _firstNameFilter,
                        decoration: const InputDecoration(
                          labelText: 'Ad',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lastNameFilter,
                        decoration: const InputDecoration(
                          labelText: 'Soyad',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _emailFilter,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tümü')),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Ara'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Content
        Expanded(
          child: usersState.when(
            data: (pageResponse) {
              if (pageResponse.content.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.person_off_outlined,
                  message: 'Kullanıcı bulunamadı',
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(usersProvider.notifier).fetchUsers(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: pageResponse.content.length,
                        itemBuilder: (context, index) {
                          final user = pageResponse.content[index];
                          return _UserCard(
                            user: user,
                            canUpdate: canUpdate,
                            canDelete: canDelete,
                            onEdit: () => _showEditDialog(context, user),
                            onDelete: () => _handleDelete(user),
                            onRoles: () => _showRolesSheet(context, user),
                          );
                        },
                      ),
                    ),
                    // Pagination
                    if (pageResponse.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: pageResponse.number > 0
                                  ? () => ref
                                      .read(usersProvider.notifier)
                                      .setPage(pageResponse.number - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              '${pageResponse.number + 1} / ${pageResponse.totalPages}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                              onPressed:
                                  pageResponse.number < pageResponse.totalPages - 1
                                      ? () => ref
                                          .read(usersProvider.notifier)
                                          .setPage(pageResponse.number + 1)
                                      : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Hata: ${e is ApiException ? e.message : 'Yüklenemedi'}'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => ref.read(usersProvider.notifier).fetchUsers(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UserFormDialog(
        onSave: (request) async {
          await ref.read(usersProvider.notifier).createUser(request as CreateUserRequest);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UserFormDialog(
        user: user,
        onSave: (request) async {
          await ref
              .read(usersProvider.notifier)
              .updateUser(user.id, request as UpdateUserRequest);
        },
      ),
    );
  }

  Future<void> _handleDelete(User user) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Kullanıcıyı Sil',
      message: '${user.username} kullanıcısını silmek istediğinize emin misiniz?',
    );
    if (confirmed) {
      try {
        await ref.read(usersProvider.notifier).deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı silindi'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is ApiException ? e.message : 'Kullanıcı silinemedi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showRolesSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UserRolesSheet(user: user),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRoles;

  const _UserCard({
    required this.user,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onRoles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    user.username.substring(0, user.username.length >= 2 ? 2 : user.username.length).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: user.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
            if (canUpdate || canDelete) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canUpdate) ...[
                    TextButton.icon(
                      onPressed: onRoles,
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Roller'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Düzenle'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.info),
                    ),
                  ],
                  if (canDelete)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Sil'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
