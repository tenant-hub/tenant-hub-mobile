import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/constants/app_colors.dart';
import 'package:tenant_hub_mobile/core/utils/text_utils.dart';
import 'package:tenant_hub_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tenant_hub_mobile/features/dashboard/presentation/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(authProvider.select((s) => s.valueOrNull?.username));
    final stats = ref.watch(dashboardStatsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardStatsProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş geldiniz, ${TextUtils.truncate(username ?? '')}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tenant Hub yönetim paneline genel bakış',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            stats.when(
              data: (data) => _buildStatsGrid(data),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Text('İstatistikler yüklenemedi'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats data) {
    final cards = [
      _StatCard(
        title: 'Gayrimenkuller',
        value: data.realEstates,
        icon: Icons.home_outlined,
        gradientColors: const [AppColors.primary, Color(0xFF7C3AED)],
      ),
      _StatCard(
        title: 'Kullanıcılar',
        value: data.users,
        icon: Icons.person_outline,
        gradientColors: const [AppColors.success, Color(0xFF059669)],
      ),
      _StatCard(
        title: 'Kiralamalar',
        value: data.rents,
        icon: Icons.attach_money,
        gradientColors: const [AppColors.warning, Color(0xFFD97706)],
      ),
      _StatCard(
        title: 'Ödemeler',
        value: data.payments,
        icon: Icons.account_balance_wallet_outlined,
        gradientColors: const [AppColors.info, Color(0xFF2563EB)],
      ),
      _StatCard(
        title: 'Kiraya Verilmiş',
        value: data.rentedRealEstates,
        icon: Icons.check_circle_outline,
        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
      ),
      _StatCard(
        title: 'Boş Gayrimenkul',
        value: data.vacantRealEstates,
        icon: Icons.home_work_outlined,
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
      _StatCard(
        title: 'Kiracılar',
        value: data.tenants,
        icon: Icons.person_pin_outlined,
        gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
      ),
      _StatCard(
        title: 'Ev Sahipleri',
        value: data.landlords,
        icon: Icons.house_outlined,
        gradientColors: const [Color(0xFFEC4899), Color(0xFFDB2777)],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => cards[i],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int? value;
  final IconData icon;
  final List<Color> gradientColors;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(colors: gradientColors),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            Text(
              value?.toString() ?? '—',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
