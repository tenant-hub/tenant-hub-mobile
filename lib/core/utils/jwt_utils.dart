import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tenant_hub_mobile/features/auth/domain/auth_user.dart';

class JwtUtils {
  JwtUtils._();

  static AuthUser parseUser(String token) {
    final payload = JwtDecoder.decode(token);
    return AuthUser(
      username: payload['sub'] as String? ?? '',
      roles: List<String>.from(payload['roles'] ?? []),
      permissions: List<String>.from(payload['permissions'] ?? []),
    );
  }

  static bool isExpired(String token) => JwtDecoder.isExpired(token);
}
