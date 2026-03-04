import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_permission_model.freezed.dart';
part 'role_permission_model.g.dart';

@freezed
class RolePermissionResponse with _$RolePermissionResponse {
  const factory RolePermissionResponse({
    required int id,
    required int roleId,
    required String roleName,
    required int permissionId,
    required String permissionName,
    required String createdDate,
    required String createdBy,
  }) = _RolePermissionResponse;

  factory RolePermissionResponse.fromJson(Map<String, dynamic> json) =>
      _$RolePermissionResponseFromJson(json);
}

@freezed
class RolePermissionRequest with _$RolePermissionRequest {
  const factory RolePermissionRequest({
    required int roleId,
    required int permissionId,
  }) = _RolePermissionRequest;

  factory RolePermissionRequest.fromJson(Map<String, dynamic> json) =>
      _$RolePermissionRequestFromJson(json);
}
