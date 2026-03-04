import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_model.freezed.dart';
part 'permission_model.g.dart';

@freezed
class Permission with _$Permission {
  const factory Permission({
    required int id,
    required String name,
    required String description,
    required String module,
    required String action,
    required String status,
    required String createdDate,
    required String createdBy,
  }) = _Permission;

  factory Permission.fromJson(Map<String, dynamic> json) =>
      _$PermissionFromJson(json);
}

@freezed
class PermissionRequest with _$PermissionRequest {
  const factory PermissionRequest({
    required String name,
    required String description,
    required String module,
    required String action,
    required String status,
  }) = _PermissionRequest;

  factory PermissionRequest.fromJson(Map<String, dynamic> json) =>
      _$PermissionRequestFromJson(json);
}
