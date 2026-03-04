import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/login_page.dart';
import 'package:tenant_hub_mobile/features/dashboard/presentation/dashboard_page.dart';
import 'package:tenant_hub_mobile/features/payments/presentation/payments_page.dart';
import 'package:tenant_hub_mobile/features/permissions/presentation/permissions_page.dart';
import 'package:tenant_hub_mobile/features/real_estates/presentation/real_estates_page.dart';
import 'package:tenant_hub_mobile/features/rents/presentation/rents_page.dart';
import 'package:tenant_hub_mobile/features/roles/presentation/roles_page.dart';
import 'package:tenant_hub_mobile/features/settings/presentation/settings_page.dart';
import 'package:tenant_hub_mobile/features/tenants/presentation/tenants_page.dart';
import 'package:tenant_hub_mobile/features/users/presentation/users_page.dart';
import 'package:tenant_hub_mobile/shared/widgets/app_drawer.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      ShellRoute(
        builder: (_, __, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/users', builder: (_, __) => const UsersPage()),
          GoRoute(path: '/roles', builder: (_, __) => const RolesPage()),
          GoRoute(path: '/permissions', builder: (_, __) => const PermissionsPage()),
          GoRoute(path: '/real-estates', builder: (_, __) => const RealEstatesPage()),
          GoRoute(path: '/rents', builder: (_, __) => const RentsPage()),
          GoRoute(path: '/payments', builder: (_, __) => const PaymentsPage()),
          GoRoute(path: '/tenants', builder: (_, __) => const TenantsPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
});

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      drawer: const AppDrawer(),
      body: child,
      backgroundColor: AppColors.background,
    );
  }
}

class TenantHubApp extends ConsumerWidget {
  const TenantHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Tenant Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        cardTheme: CardThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(0, 44),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      routerConfig: router,
    );
  }
}
