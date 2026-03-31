import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/payments/domain/payment_model.dart';
import 'package:tenant_hub_mobile/features/payments/presentation/payments_provider.dart';
import 'package:tenant_hub_mobile/shared/widgets/confirm_dialog.dart';
import 'package:tenant_hub_mobile/shared/widgets/empty_state_widget.dart';
import 'package:tenant_hub_mobile/shared/widgets/status_chip.dart';

DateTime _parseDateString(String s) {
  // ISO format: "2026-03-28T00:00:00" veya "2026-03-28T00:00:00.000Z"
  if (s.contains('-') || s.contains('T')) {
    return DateTime.parse(s);
  }
  // yyyyMMddHHmmss format: "20260328000000"
  return DateTime(
    int.parse(s.substring(0, 4)),
    int.parse(s.substring(4, 6)),
    int.parse(s.substring(6, 8)),
    s.length >= 10 ? int.parse(s.substring(8, 10)) : 0,
    s.length >= 12 ? int.parse(s.substring(10, 12)) : 0,
    s.length >= 14 ? int.parse(s.substring(12, 14)) : 0,
  );
}

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  String _formatCurrency(double amount, String currency) {
    final symbols = {'TRY': '\u20BA', 'USD': '\$', 'EUR': '\u20AC', 'GBP': '\u00A3'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol${NumberFormat('#,##0.00', 'tr_TR').format(amount)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentsProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final canCreate = authNotifier.hasPermission(PermissionKeys.paymentCreate);
    final canUpdate = authNotifier.hasPermission(PermissionKeys.paymentUpdate);
    final canDelete = authNotifier.hasPermission(PermissionKeys.paymentDelete);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ödemeler',
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
                return const EmptyStateWidget(
                    icon: Icons.account_balance_wallet_outlined, message: 'Ödeme bulunamadı');
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(paymentsProvider.notifier).fetchPayments(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: pageResponse.content.length,
                        itemBuilder: (context, index) {
                          final payment = pageResponse.content[index];
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
                                        backgroundColor: AppColors.info.withValues(alpha: 0.1),
                                        child: const Icon(Icons.account_balance_wallet,
                                            color: AppColors.info, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Kira #${payment.rentId}',
                                                style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text(
                                              _formatCurrency(payment.amount, payment.currency),
                                              style: const TextStyle(
                                                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusChip(status: payment.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd.MM.yyyy').format(_parseDateString(payment.paymentDate)),
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (canUpdate || canDelete) ...[
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (canUpdate)
                                          TextButton.icon(
                                            onPressed: () => _showFormDialog(context, ref, payment: payment),
                                            icon: const Icon(Icons.edit_outlined, size: 16),
                                            label: const Text('Düzenle'),
                                            style: TextButton.styleFrom(foregroundColor: AppColors.info),
                                          ),
                                        if (canDelete)
                                          TextButton.icon(
                                            onPressed: () => _handleDelete(context, ref, payment),
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
                                  ? () => ref.read(paymentsProvider.notifier).setPage(pageResponse.number - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('${pageResponse.number + 1} / ${pageResponse.totalPages}'),
                            IconButton(
                              onPressed: pageResponse.number < pageResponse.totalPages - 1
                                  ? () => ref.read(paymentsProvider.notifier).setPage(pageResponse.number + 1)
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

  void _showFormDialog(BuildContext context, WidgetRef ref, {Payment? payment}) {
    final rentIdCtrl = TextEditingController(text: payment?.rentId.toString());
    final amountCtrl = TextEditingController(text: payment?.amount.toString());
    String currency = payment?.currency ?? 'TRY';
    DateTime selectedDate = payment != null ? _parseDateString(payment.paymentDate) : DateTime.now();
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
                    Text(payment != null ? 'Ödeme Düzenle' : 'Yeni Ödeme',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: rentIdCtrl,
                      decoration: const InputDecoration(labelText: 'Kira ID'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ödeme Tarihi'),
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
                      decoration: const InputDecoration(labelText: 'Tutar'),
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
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final request = PaymentRequest(
                          rentId: int.parse(rentIdCtrl.text.trim()),
                          amount: double.parse(amountCtrl.text.trim()),
                          currency: currency,
                          paymentDate: DateFormat('yyyyMMddHHmmss').format(selectedDate),
                        );
                        try {
                          if (payment != null) {
                            await ref.read(paymentsProvider.notifier).updatePayment(payment.id, request);
                          } else {
                            await ref.read(paymentsProvider.notifier).createPayment(request);
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
                      child: Text(payment != null ? 'Güncelle' : 'Oluştur'),
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

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Payment payment) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Ödemeyi Sil', message: 'Bu ödemeyi silmek istediğinize emin misiniz?');
    if (confirmed) {
      try {
        await ref.read(paymentsProvider.notifier).deletePayment(payment.id);
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
