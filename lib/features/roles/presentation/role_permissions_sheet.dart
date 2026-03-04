import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/permissions/presentation/permissions_provider.dart';
import 'package:tenant_hub_mobile/features/roles/domain/role_model.dart';
import 'package:tenant_hub_mobile/features/roles/domain/role_permission_model.dart';
import 'package:tenant_hub_mobile/features/roles/presentation/roles_provider.dart';

class RolePermissionsSheet extends ConsumerStatefulWidget {
  final Role role;

  const RolePermissionsSheet({super.key, required this.role});

  @override
  ConsumerState<RolePermissionsSheet> createState() => _RolePermissionsSheetState();
}

class _RolePermissionsSheetState extends ConsumerState<RolePermissionsSheet> {
  int? _selectedPermissionId;
  bool _assigning = false;
  List<RolePermissionResponse> _rolePermissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _loading = true);
    try {
      final perms = await ref
          .read(rolePermissionRepositoryProvider)
          .getPermissionsByRoleId(widget.role.id);
      setState(() {
        _rolePermissions = perms;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _assignPermission() async {
    if (_selectedPermissionId == null) return;
    setState(() => _assigning = true);
    try {
      await ref.read(rolePermissionRepositoryProvider).assignPermissionToRole(
            RolePermissionRequest(
                roleId: widget.role.id, permissionId: _selectedPermissionId!),
          );
      _selectedPermissionId = null;
      await _loadPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetki atandı'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Yetki atanamadı'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Future<void> _removePermission(int rpId) async {
    try {
      await ref.read(rolePermissionRepositoryProvider).removeRolePermission(rpId);
      await _loadPermissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Yetki kaldırılamadı'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPermsState = ref.watch(allPermissionsProvider);
    final assignedPermIds = _rolePermissions.map((rp) => rp.permissionId).toSet();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.role.name} — Yetki Yönetimi',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            allPermsState.when(
              data: (perms) {
                final available = perms.where((p) => !assignedPermIds.contains(p.id)).toList();
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedPermissionId,
                        decoration: const InputDecoration(labelText: 'Yetki seçin...', isDense: true),
                        items: available
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedPermissionId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: (_selectedPermissionId != null && !_assigning)
                          ? _assignPermission
                          : null,
                      icon: _assigning
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add, size: 18),
                      label: const Text('Ata'),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Yetkiler yüklenemedi'),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rolePermissions.isEmpty
                      ? const Center(child: Text('Atanmış yetki yok', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _rolePermissions.length,
                          itemBuilder: (context, index) {
                            final rp = _rolePermissions[index];
                            return ListTile(
                              leading: const Icon(Icons.security, color: AppColors.info),
                              title: Text(rp.permissionName),
                              subtitle: Text('Atayan: ${rp.createdBy}', style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                onPressed: () => _removePermission(rp.id),
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
