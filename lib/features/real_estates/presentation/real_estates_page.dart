import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/real_estates/domain/real_estate_model.dart';
import 'package:tenant_hub_mobile/features/real_estates/presentation/real_estates_provider.dart';
import 'package:tenant_hub_mobile/core/utils/text_utils.dart';
import 'package:tenant_hub_mobile/shared/widgets/confirm_dialog.dart';
import 'package:tenant_hub_mobile/shared/widgets/empty_state_widget.dart';
import 'package:tenant_hub_mobile/shared/widgets/status_chip.dart';

class RealEstatesPage extends ConsumerWidget {
  const RealEstatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(realEstatesProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final canCreate = authNotifier.hasPermission(PermissionKeys.realEstateCreate);
    final canUpdate = authNotifier.hasPermission(PermissionKeys.realEstateUpdate);
    final canDelete = authNotifier.hasPermission(PermissionKeys.realEstateDelete);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gayrimenkuller',
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
                return const EmptyStateWidget(icon: Icons.home_outlined, message: 'Gayrimenkul bulunamadı');
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(realEstatesProvider.notifier).fetchRealEstates(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: pageResponse.content.length,
                        itemBuilder: (context, index) {
                          final re = pageResponse.content[index];
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
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: const Icon(Icons.home, color: AppColors.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(TextUtils.truncate(re.name), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            Text(TextUtils.truncate(re.type), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      StatusChip(status: re.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          TextUtils.truncate('${re.province}, ${re.district}'),
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (re.tenantName != null || re.landlordName != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          if (re.landlordName != null) ...[
                                            const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text('Ev sahibi: ${TextUtils.truncate(re.landlordName!)}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                          if (re.tenantName != null) ...[
                                            const SizedBox(width: 12),
                                            const Icon(Icons.group, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text('Kiracı: ${TextUtils.truncate(re.tenantName!)}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  if (re.note != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.notes_outlined, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              TextUtils.truncate(re.note!),
                                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (canUpdate || canDelete) ...[
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (canUpdate)
                                          TextButton.icon(
                                            onPressed: () => _showFormDialog(context, ref, realEstate: re),
                                            icon: const Icon(Icons.edit_outlined, size: 16),
                                            label: const Text('Düzenle'),
                                            style: TextButton.styleFrom(foregroundColor: AppColors.info),
                                          ),
                                        if (canDelete)
                                          TextButton.icon(
                                            onPressed: () => _handleDelete(context, ref, re),
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
                                  ? () => ref.read(realEstatesProvider.notifier).setPage(pageResponse.number - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('${pageResponse.number + 1} / ${pageResponse.totalPages}'),
                            IconButton(
                              onPressed: pageResponse.number < pageResponse.totalPages - 1
                                  ? () => ref.read(realEstatesProvider.notifier).setPage(pageResponse.number + 1)
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
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      e is ApiException ? e.message : 'Gayrimenkuller yüklenemedi',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => ref.read(realEstatesProvider.notifier).fetchRealEstates(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Tekrar Dene'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, {RealEstate? realEstate}) {
    final nameCtrl = TextEditingController(text: realEstate?.name);
    final descCtrl = TextEditingController(text: realEstate?.description);
    final typeCtrl = TextEditingController(text: realEstate?.type);
    final provinceCtrl = TextEditingController(text: realEstate?.province);
    final districtCtrl = TextEditingController(text: realEstate?.district);
    final neighborhoodCtrl = TextEditingController(text: realEstate?.neighborhood);
    final addressCtrl = TextEditingController(text: realEstate?.address);
    final noteCtrl = TextEditingController(text: realEstate?.note);
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(realEstate != null ? 'Gayrimenkul Düzenle' : 'Yeni Gayrimenkul',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 2),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(labelText: 'Tip (Apartment, Villa...)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: provinceCtrl, decoration: const InputDecoration(labelText: 'İl'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'İlçe'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: neighborhoodCtrl, decoration: const InputDecoration(labelText: 'Mahalle'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Adres'), maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Not'),
                    maxLines: 3,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final request = RealEstateRequest(
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        type: typeCtrl.text.trim(),
                        province: provinceCtrl.text.trim(),
                        district: districtCtrl.text.trim(),
                        neighborhood: neighborhoodCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      );
                      try {
                        if (realEstate != null) {
                          await ref.read(realEstatesProvider.notifier).updateRealEstate(realEstate.id, request);
                        } else {
                          await ref.read(realEstatesProvider.notifier).createRealEstate(request);
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
                    child: Text(realEstate != null ? 'Güncelle' : 'Oluştur'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, RealEstate re) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Gayrimenkulü Sil', message: '${re.name} gayrimenkulünü silmek istediğinize emin misiniz?');
    if (confirmed) {
      try {
        await ref.read(realEstatesProvider.notifier).deleteRealEstate(re.id);
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
