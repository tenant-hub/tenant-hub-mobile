import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/core/network/api_exceptions.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/landlords/domain/landlord_model.dart';
import 'package:tenant_hub_mobile/features/landlords/presentation/landlords_provider.dart';
import 'package:tenant_hub_mobile/features/users/data/user_repository.dart';
import 'package:tenant_hub_mobile/features/users/domain/user_model.dart';
import 'package:tenant_hub_mobile/shared/widgets/confirm_dialog.dart';
import 'package:tenant_hub_mobile/shared/widgets/empty_state_widget.dart';

class LandlordsPage extends ConsumerWidget {
  const LandlordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(landlordsProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final canCreate = authNotifier.hasPermission(PermissionKeys.landlordCreate);
    final canUpdate = authNotifier.hasPermission(PermissionKeys.landlordUpdate);
    final canDelete = authNotifier.hasPermission(PermissionKeys.landlordDelete);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ev Sahipleri',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => _showFormSheet(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni'),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
            ],
          ),
        ),
        Expanded(
          child: state.when(
            data: (pageResponse) {
              if (pageResponse.content.isEmpty) {
                return const EmptyStateWidget(
                    icon: Icons.home_work_outlined,
                    message: 'Ev sahibi bulunamadı');
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(landlordsProvider.notifier).fetchLandlords(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: pageResponse.content.length,
                        itemBuilder: (context, index) {
                          final landlord = pageResponse.content[index];
                          final displayName = _buildDisplayName(landlord);
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
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        child: const Icon(Icons.person,
                                            color: AppColors.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15),
                                        ),
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
                                            onPressed: () => _showFormSheet(
                                                context, ref,
                                                landlord: landlord),
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 16),
                                            label: const Text('Düzenle'),
                                            style: TextButton.styleFrom(
                                                foregroundColor: AppColors.info),
                                          ),
                                        if (canDelete)
                                          TextButton.icon(
                                            onPressed: () => _handleDelete(
                                                context, ref, landlord),
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 16),
                                            label: const Text('Sil'),
                                            style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.error),
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
                                  ? () => ref
                                      .read(landlordsProvider.notifier)
                                      .setPage(pageResponse.number - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                                '${pageResponse.number + 1} / ${pageResponse.totalPages}'),
                            IconButton(
                              onPressed: pageResponse.number <
                                      pageResponse.totalPages - 1
                                  ? () => ref
                                      .read(landlordsProvider.notifier)
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
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      e is ApiException
                          ? e.message
                          : 'Ev sahipleri yüklenemedi',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(landlordsProvider.notifier).fetchLandlords(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Tekrar Dene'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
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

  String _buildDisplayName(Landlord landlord) {
    if (landlord.usersFullName != null &&
        landlord.usersFullName!.isNotEmpty) {
      return landlord.usersFullName!;
    }
    return 'Ev Sahibi #${landlord.id}';
  }

  void _showFormSheet(BuildContext context, WidgetRef ref,
      {Landlord? landlord}) async {
    final userRepo = ref.read(userRepositoryProvider);
    List<User> users = [];

    try {
      final page = await userRepo.getUsers(size: 100, sort: 'username,asc');
      users = page.content;
    } catch (_) {}

    if (!context.mounted) return;

    int? selectedUserId = landlord?.usersId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _LandlordFormSheet(
        landlord: landlord,
        users: users,
        initialUserId: selectedUserId,
        onSubmit: (usersId) async {
          final request = LandlordRequest(usersId: usersId);
          try {
            if (landlord != null) {
              await ref
                  .read(landlordsProvider.notifier)
                  .update(landlord.id, request);
            } else {
              await ref.read(landlordsProvider.notifier).create(request);
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content:
                    Text(e is ApiException ? e.message : 'İşlem başarısız'),
                backgroundColor: AppColors.error,
              ));
            }
          }
        },
      ),
    );
  }

  Future<void> _handleDelete(
      BuildContext context, WidgetRef ref, Landlord landlord) async {
    final displayName = _buildDisplayName(landlord);
    final confirmed = await showConfirmDialog(context,
        title: 'Ev Sahibini Sil',
        message: '$displayName ev sahibini silmek istediğinize emin misiniz?');
    if (confirmed) {
      try {
        await ref.read(landlordsProvider.notifier).delete(landlord.id);
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

class _LandlordFormSheet extends StatefulWidget {
  final Landlord? landlord;
  final List<User> users;
  final int? initialUserId;
  final Future<void> Function(int usersId) onSubmit;

  const _LandlordFormSheet({
    this.landlord,
    required this.users,
    this.initialUserId,
    required this.onSubmit,
  });

  @override
  State<_LandlordFormSheet> createState() => _LandlordFormSheetState();
}

class _LandlordFormSheetState extends State<_LandlordFormSheet> {
  int? _selectedUserId;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.initialUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.landlord != null ? 'Ev Sahibi Düzenle' : 'Yeni Ev Sahibi',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                if (widget.users.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kullanıcı listesi yüklenemedi. Lütfen tekrar deneyin.',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _selectedUserId,
                    decoration: const InputDecoration(labelText: 'Kullanıcı'),
                    items: widget.users
                        .map((u) => DropdownMenuItem<int>(
                              value: u.id,
                              child: Text(
                                '${u.firstName} ${u.lastName} (@${u.username})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUserId = v),
                    validator: (v) => v == null ? 'Kullanıcı seçiniz' : null,
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isLoading = true);
                          await widget.onSubmit(_selectedUserId!);
                          if (mounted) setState(() => _isLoading = false);
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.landlord != null ? 'Güncelle' : 'Oluştur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
