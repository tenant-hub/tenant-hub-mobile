import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/permissions/domain/permission_model.dart';
import 'package:tenant_hub_mobile/features/permissions/presentation/permissions_provider.dart';
import 'package:tenant_hub_mobile/shared/widgets/confirm_dialog.dart';
import 'package:tenant_hub_mobile/shared/widgets/empty_state_widget.dart';
import 'package:tenant_hub_mobile/shared/widgets/status_chip.dart';

class PermissionsPage extends ConsumerWidget {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionsProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final canCreate = authNotifier.hasPermission(PermissionKeys.permissionCreate);
    final canUpdate = authNotifier.hasPermission(PermissionKeys.permissionUpdate);
    final canDelete = authNotifier.hasPermission(PermissionKeys.permissionDelete);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Yetkiler',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => _showFormDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
            ],
          ),
        ),
        Expanded(
          child: state.when(
            data: (pageResponse) {
              if (pageResponse.content.isEmpty) {
                return const EmptyStateWidget(icon: Icons.security_outlined, message: 'Yetki bulunamadı');
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(permissionsProvider.notifier).fetchPermissions(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: pageResponse.content.length,
                        itemBuilder: (context, index) {
                          final perm = pageResponse.content[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.info.withValues(alpha: 0.1),
                                child: const Icon(Icons.security, color: AppColors.info, size: 20),
                              ),
                              title: Text(perm.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('${perm.module} / ${perm.action}', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusChip(status: perm.status),
                                  if (canUpdate || canDelete)
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') _showFormDialog(context, ref, permission: perm);
                                        if (v == 'delete') _handleDelete(context, ref, perm);
                                      },
                                      itemBuilder: (_) => [
                                        if (canUpdate) const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                        if (canDelete) const PopupMenuItem(value: 'delete', child: Text('Sil')),
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
                                  ? () => ref.read(permissionsProvider.notifier).setPage(pageResponse.number - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('${pageResponse.number + 1} / ${pageResponse.totalPages}'),
                            IconButton(
                              onPressed: pageResponse.number < pageResponse.totalPages - 1
                                  ? () => ref.read(permissionsProvider.notifier).setPage(pageResponse.number + 1)
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

  void _showFormDialog(BuildContext context, WidgetRef ref, {Permission? permission}) {
    final nameCtrl = TextEditingController(text: permission?.name);
    final descCtrl = TextEditingController(text: permission?.description);
    final moduleCtrl = TextEditingController(text: permission?.module);
    final actionCtrl = TextEditingController(text: permission?.action);
    String status = permission?.status ?? 'ACTIVE';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(permission != null ? 'Yetki Düzenle' : 'Yeni Yetki',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Yetki Adı'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Açıklama')),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: moduleCtrl,
                      decoration: const InputDecoration(labelText: 'Modül'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: actionCtrl.text.isNotEmpty ? actionCtrl.text : null,
                      decoration: const InputDecoration(labelText: 'Aksiyon'),
                      items: const [
                        DropdownMenuItem(value: 'CREATE', child: Text('CREATE')),
                        DropdownMenuItem(value: 'READ', child: Text('READ')),
                        DropdownMenuItem(value: 'UPDATE', child: Text('UPDATE')),
                        DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
                      ],
                      onChanged: (v) => actionCtrl.text = v ?? '',
                      validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Durum'),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                      ],
                      onChanged: (v) => setModalState(() => status = v!),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final request = PermissionRequest(
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          module: moduleCtrl.text.trim(),
                          action: actionCtrl.text.trim(),
                          status: status,
                        );
                        try {
                          if (permission != null) {
                            await ref.read(permissionsProvider.notifier).updatePermission(permission.id, request);
                          } else {
                            await ref.read(permissionsProvider.notifier).createPermission(request);
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
                      child: Text(permission != null ? 'Güncelle' : 'Oluştur'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Permission perm) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Yetkiyi Sil', message: '${perm.name} yetkisini silmek istediğinize emin misiniz?');
    if (confirmed) {
      try {
        await ref.read(permissionsProvider.notifier).deletePermission(perm.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException ? e.message : 'Silinemedi'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }
}
