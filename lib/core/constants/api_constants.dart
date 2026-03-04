import 'dart:io';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // Users
  static const String users = '/users';

  // Roles
  static const String roles = '/roles';

  // Permissions
  static const String permissions = '/permissions';

  // User-Roles
  static const String userRoles = '/user-roles';

  // Role-Permissions
  static const String rolePermissions = '/role-permissions';

  // Real Estates
  static const String realEstates = '/real-estates';

  // Rents
  static const String rents = '/rents';

  // Payments
  static const String payments = '/payments';
}
