import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_model.freezed.dart';
part 'role_model.g.dart';

@freezed
class Role with _$Role {
  const factory Role({
    required int id,
    required String name,
    required String description,
    required String status,
    required String createdDate,
    required String createdBy,
  }) = _Role;

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
}

@freezed
class RoleRequest with _$RoleRequest {
  const factory RoleRequest({
    required String name,
    required String description,
  }) = _RoleRequest;

  factory RoleRequest.fromJson(Map<String, dynamic> json) =>
      _$RoleRequestFromJson(json);
}
