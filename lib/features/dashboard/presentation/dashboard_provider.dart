import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenant_hub_mobile/core/network/dio_client.dart';
import 'package:tenant_hub_mobile/core/constants/api_constants.dart';

class DashboardStats {
  final int? realEstates;
  final int? users;
  final int? rents;
  final int? payments;

  const DashboardStats({this.realEstates, this.users, this.rents, this.payments});
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final dio = ref.watch(dioProvider);

  Future<int?> fetchCount(String path) async {
    try {
      final response = await dio.get(path, queryParameters: {'page': 0, 'size': 1});
      return response.data['totalElements'] as int?;
    } catch (_) {
      return null;
    }
  }

  final results = await Future.wait([
    fetchCount(ApiConstants.realEstates),
    fetchCount(ApiConstants.users),
    fetchCount(ApiConstants.rents),
    fetchCount(ApiConstants.payments),
  ]);

  return DashboardStats(
    realEstates: results[0],
    users: results[1],
    rents: results[2],
    payments: results[3],
  );
});
