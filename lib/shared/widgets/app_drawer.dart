import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/constants/permission_keys.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';

class _MenuItem {
  final String path;
  final IconData icon;
  final String label;
  final String? requiredPermission;

  const _MenuItem({
    required this.path,
    required this.icon,
    required this.label,
    this.requiredPermission,
  });
}

const _allMenuItems = [
  _MenuItem(path: '/dashboard', icon: Icons.dashboard_outlined, label: 'Dashboard'),
  _MenuItem(
      path: '/users',
      icon: Icons.person_outline,
      label: 'Kullanıcılar',
      requiredPermission: PermissionKeys.userRead),
  _MenuItem(
      path: '/roles',
      icon: Icons.star_outline,
      label: 'Roller',
      requiredPermission: PermissionKeys.rolesRead),
  _MenuItem(
      path: '/permissions',
      icon: Icons.security_outlined,
      label: 'Yetkiler',
      requiredPermission: PermissionKeys.permissionRead),
  _MenuItem(
      path: '/real-estates',
      icon: Icons.home_outlined,
      label: 'Gayrimenkuller',
      requiredPermission: PermissionKeys.realEstateRead),
  _MenuItem(
      path: '/rents',
      icon: Icons.attach_money,
      label: 'Kiralama',
      requiredPermission: PermissionKeys.rentRead),
  _MenuItem(
      path: '/payments',
      icon: Icons.account_balance_wallet_outlined,
      label: 'Ödemeler',
      requiredPermission: PermissionKeys.paymentRead),
  _MenuItem(
      path: '/tenants',
      icon: Icons.group_outlined,
      label: 'Kiracılar',
      requiredPermission: PermissionKeys.tenantRead),
  _MenuItem(path: '/settings', icon: Icons.settings_outlined, label: 'Ayarlar'),
];

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final user = authState.valueOrNull;
    final currentPath = GoRouterState.of(context).matchedLocation;

    final visibleItems = _allMenuItems.where((item) {
      if (item.requiredPermission == null) return true;
      return authNotifier.hasPermission(item.requiredPermission!);
    }).toList();

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDarkest,
              AppColors.primaryDarker,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tenant Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white24, height: 1),

              // Menu items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    final isSelected = currentPath == item.path;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: ListTile(
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.path);
                        },
                      ),
                    );
                  },
                ),
              ),

              // User info + logout
              const Divider(color: Colors.white24, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        (user?.username ?? '').substring(0, (user?.username ?? '').length >= 2 ? 2 : (user?.username ?? '').length).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.username ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
