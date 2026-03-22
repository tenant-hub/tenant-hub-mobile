import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/rents/domain/rent_model.dart';
import 'package:tenant_hub_mobile/features/rents/presentation/rents_provider.dart';
import 'package:tenant_hub_mobile/shared/widgets/confirm_dialog.dart';
import 'package:tenant_hub_mobile/shared/widgets/empty_state_widget.dart';
import 'package:tenant_hub_mobile/shared/widgets/status_chip.dart';

class RentsPage extends ConsumerWidget {
  const RentsPage({super.key});

  String _formatCurrency(double amount, String currency) {
    final symbols = {'TRY': '\u20BA', 'USD': '\$', 'EUR': '\u20AC', 'GBP': '\u00A3'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol${NumberFormat('#,##0.00', 'tr_TR').format(amount)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rentsProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final canCreate = authNotifier.hasPermission(PermissionKeys.rentCreate);
    final canUpdate = authNotifier.hasPermission(PermissionKeys.rentUpdate);
    final canDelete = authNotifier.hasPermission(PermissionKeys.rentDelete);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kiralamalar',
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
                return const EmptyStateWidget(icon: Icons.money_off, message: 'Kiralama bulunamadı');
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(rentsProvider.notifier).fetchRents(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: pageResponse.content.length,
                        itemBuilder: (context, index) {
                          final rent = pageResponse.content[index];
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
                                        backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                                        child: const Icon(Icons.attach_money, color: AppColors.warning, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(rent.realEstateName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text(
                                              _formatCurrency(rent.rentAmount, rent.currency),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusChip(status: rent.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd.MM.yyyy').format(DateTime.parse(rent.rentDate)),
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                      if (rent.increaseRate != null) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.trending_up, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '%${rent.increaseRate!.toStringAsFixed(2)}',
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
                                        if (canUpdate)
                                          TextButton.icon(
                                            onPressed: () => _showFormDialog(context, ref, rent: rent),
                                            icon: const Icon(Icons.edit_outlined, size: 16),
                                            label: const Text('Düzenle'),
                                            style: TextButton.styleFrom(foregroundColor: AppColors.info),
                                          ),
                                        if (canDelete)
                                          TextButton.icon(
                                            onPressed: () => _handleDelete(context, ref, rent),
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
                                  ? () => ref.read(rentsProvider.notifier).setPage(pageResponse.number - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('${pageResponse.number + 1} / ${pageResponse.totalPages}'),
                            IconButton(
                              onPressed: pageResponse.number < pageResponse.totalPages - 1
                                  ? () => ref.read(rentsProvider.notifier).setPage(pageResponse.number + 1)
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

  void _showFormDialog(BuildContext context, WidgetRef ref, {Rent? rent}) {
    final realEstateIdCtrl = TextEditingController(text: rent?.realEstateId.toString());
    final amountCtrl = TextEditingController(text: rent?.rentAmount.toString());
    final increaseRateCtrl = TextEditingController(
      text: rent?.increaseRate != null ? rent!.increaseRate!.toString() : '',
    );
    String currency = rent?.currency ?? 'TRY';
    DateTime selectedDate = rent != null ? DateTime.parse(rent.rentDate) : DateTime.now();
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
                    Text(rent != null ? 'Kiralama Düzenle' : 'Yeni Kiralama',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: realEstateIdCtrl,
                      decoration: const InputDecoration(labelText: 'Gayrimenkul ID'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kira Tarihi'),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setModalState(() => selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Kira Tutarı'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: currency,
                      decoration: const InputDecoration(labelText: 'Para Birimi'),
                      items: const [
                        DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (v) => setModalState(() => currency = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: increaseRateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Zam Oranı (%)',
                        hintText: 'Opsiyonel (0-100)',
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null) return 'Geçerli bir sayı girin';
                        if (parsed < 0 || parsed > 100) return '0-100 arasında olmalıdır';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final increaseRateText = increaseRateCtrl.text.trim();
                        final request = RentRequest(
                          realEstateId: int.parse(realEstateIdCtrl.text.trim()),
                          rentDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                          rentAmount: double.parse(amountCtrl.text.trim()),
                          currency: currency,
                          increaseRate: increaseRateText.isNotEmpty ? double.parse(increaseRateText) : null,
                        );
                        try {
                          if (rent != null) {
                            await ref.read(rentsProvider.notifier).updateRent(rent.id, request);
                          } else {
                            await ref.read(rentsProvider.notifier).createRent(request);
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
                      child: Text(rent != null ? 'Güncelle' : 'Oluştur'),
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

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Rent rent) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Kiralamayı Sil', message: 'Bu kiralamayı silmek istediğinize emin misiniz?');
    if (confirmed) {
      try {
        await ref.read(rentsProvider.notifier).deleteRent(rent.id);
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
