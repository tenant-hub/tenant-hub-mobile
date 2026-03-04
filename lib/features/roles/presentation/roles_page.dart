import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/roles/domain/role_model.dart';
import 'package:tenant_hub_mobile/features/roles/presentation/role_permissions_sheet.dart';
import 'package:tenant_hub_mobile/features/roles/presentation/roles_provider.dart';
import 'package:tenant_hub_mobile/shared/widgets/confirm_dialog.dart';
import 'package:tenant_hub_mobile/shared/widgets/empty_state_widget.dart';
import 'package:tenant_hub_mobile/shared/widgets/status_chip.dart';

class RolesPage extends ConsumerStatefulWidget {
  const RolesPage({super.key});

  @override
  ConsumerState<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends ConsumerState<RolesPage> {
  @override
  Widget build(BuildContext context) {
    final rolesState = ref.watch(rolesProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final canCreate = authNotifier.hasPermission(PermissionKeys.rolesCreate);
    final canUpdate = authNotifier.hasPermission(PermissionKeys.rolesUpdate);
    final canDelete = authNotifier.hasPermission(PermissionKeys.rolesDelete);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Roller',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => _showFormDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
            ],
          ),
        ),
        Expanded(
          child: rolesState.when(
            data: (pageResponse) {
              if (pageResponse.content.isEmpty) {
                return const EmptyStateWidget(icon: Icons.star_outline, message: 'Rol bulunamadı');
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(rolesProvider.notifier).fetchRoles(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: pageResponse.content.length,
                        itemBuilder: (context, index) {
                          final role = pageResponse.content[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                                child: const Icon(Icons.star, color: AppColors.warning, size: 20),
                              ),
                              title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(role.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusChip(status: role.status),
                                  if (canUpdate || canDelete)
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'permissions') _showPermissionsSheet(context, role);
                                        if (v == 'edit') _showFormDialog(context, role: role);
                                        if (v == 'delete') _handleDelete(role);
                                      },
                                      itemBuilder: (_) => [
                                        if (canUpdate)
                                          const PopupMenuItem(value: 'permissions', child: Text('Yetkiler')),
                                        if (canUpdate)
                                          const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                        if (canDelete)
                                          const PopupMenuItem(value: 'delete', child: Text('Sil')),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (pageResponse.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: pageResponse.number > 0
                                  ? () => ref.read(rolesProvider.notifier).setPage(pageResponse.number - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('${pageResponse.number + 1} / ${pageResponse.totalPages}'),
                            IconButton(
                              onPressed: pageResponse.number < pageResponse.totalPages - 1
                                  ? () => ref.read(rolesProvider.notifier).setPage(pageResponse.number + 1)
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
            error: (e, _) => Center(child: Text('Hata: ${e is ApiException ? e.message : 'Yüklenemedi'}')),
          ),
        ),
      ],
    );
  }

  void _showFormDialog(BuildContext context, {Role? role}) {
    final nameCtrl = TextEditingController(text: role?.name);
    final descCtrl = TextEditingController(text: role?.description);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(role != null ? 'Rol Düzenle' : 'Yeni Rol',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Rol Adı'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final request = RoleRequest(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                    try {
                      if (role != null) {
                        await ref.read(rolesProvider.notifier).updateRole(role.id, request);
                      } else {
                        await ref.read(rolesProvider.notifier).createRole(request);
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(e is ApiException ? e.message : 'İşlem başarısız'),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    }
                  },
                  child: Text(role != null ? 'Güncelle' : 'Oluştur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(Role role) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Rolü Sil', message: '${role.name} rolünü silmek istediğinize emin misiniz?');
    if (confirmed) {
      try {
        await ref.read(rolesProvider.notifier).deleteRole(role.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException ? e.message : 'Silinemedi'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }

  void _showPermissionsSheet(BuildContext context, Role role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RolePermissionsSheet(role: role),
    );
  }
}
