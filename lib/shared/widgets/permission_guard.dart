import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';

class PermissionGuard extends ConsumerWidget {
  final String permission;
  final Widget child;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(authProvider.notifier).hasPermission(permission);
    return hasPermission ? child : const SizedBox.shrink();
  }
}
