import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/roles/presentation/roles_provider.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_model.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_role_model.dart';
import 'package:tenant_hub_mobile/features/users/presentation/users_provider.dart';

class UserRolesSheet extends ConsumerStatefulWidget {
  final User user;

  const UserRolesSheet({super.key, required this.user});

  @override
  ConsumerState<UserRolesSheet> createState() => _UserRolesSheetState();
}

class _UserRolesSheetState extends ConsumerState<UserRolesSheet> {
  int? _selectedRoleId;
  bool _assigning = false;
  List<UserRoleResponse> _userRoles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _loading = true);
    try {
      final roles = await ref
          .read(userRoleRepositoryProvider)
          .getRolesByUserId(widget.user.id);
      setState(() {
        _userRoles = roles;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _assignRole() async {
    if (_selectedRoleId == null) return;
    setState(() => _assigning = true);
    try {
      await ref.read(userRoleRepositoryProvider).assignRoleToUser(
            UserRoleRequest(userId: widget.user.id, roleId: _selectedRoleId!),
          );
      _selectedRoleId = null;
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol atandı'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Rol atanamadı'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Future<void> _removeRole(int urId) async {
    try {
      await ref.read(userRoleRepositoryProvider).removeUserRole(urId);
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol kaldırıldı'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Rol kaldırılamadı'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRolesState = ref.watch(allRolesProvider);
    final assignedRoleIds = _userRoles.map((ur) => ur.roleId).toSet();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.user.username} — Rol Yönetimi',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Assign role
            allRolesState.when(
              data: (roles) {
                final available =
                    roles.where((r) => !assignedRoleIds.contains(r.id)).toList();
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        decoration: const InputDecoration(
                          labelText: 'Rol seçin...',
                          isDense: true,
                        ),
                        items: available
                            .map((r) =>
                                DropdownMenuItem(value: r.id, child: Text(r.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRoleId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: (_selectedRoleId != null && !_assigning)
                          ? _assignRole
                          : null,
                      icon: _assigning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add, size: 18),
                      label: const Text('Ata'),
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Roller yüklenemedi'),
            ),

            const SizedBox(height: 16),

            // Assigned roles list
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _userRoles.isEmpty
                      ? const Center(
                          child: Text(
                            'Atanmış rol yok',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _userRoles.length,
                          itemBuilder: (context, index) {
                            final ur = _userRoles[index];
                            return ListTile(
                              leading: const Icon(Icons.star, color: AppColors.warning),
                              title: Text(ur.roleName),
                              subtitle: Text(
                                'Atayan: ${ur.createdBy}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                onPressed: () => _removeRole(ur.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
