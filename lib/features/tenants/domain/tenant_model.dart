import 'package:freezed_annotation/freezed_annotation.dart';

part 'tenant_model.freezed.dart';
part 'tenant_model.g.dart';

@freezed
class Tenant with _$Tenant {
  const factory Tenant({
    required int id,
    required int usersId,
    String? username,
    String? firstName,
    String? lastName,
  }) = _Tenant;

  factory Tenant.fromJson(Map<String, dynamic> json) => _$TenantFromJson(json);
}

@freezed
class TenantRequest with _$TenantRequest {
  const factory TenantRequest({
    required int usersId,
  }) = _TenantRequest;

  factory TenantRequest.fromJson(Map<String, dynamic> json) =>
      _$TenantRequestFromJson(json);
}
