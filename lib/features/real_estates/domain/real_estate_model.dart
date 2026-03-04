import 'package:freezed_annotation/freezed_annotation.dart';

part 'real_estate_model.freezed.dart';
part 'real_estate_model.g.dart';

@freezed
class RealEstate with _$RealEstate {
  const factory RealEstate({
    required int id,
    required String name,
    required String description,
    required String type,
    required String province,
    required String district,
    required String neighborhood,
    required String address,
    int? tenantId,
    String? tenantName,
    int? landlordId,
    String? landlordName,
    required String status,
    required String createdDate,
    required String createdBy,
  }) = _RealEstate;

  factory RealEstate.fromJson(Map<String, dynamic> json) =>
      _$RealEstateFromJson(json);
}

@freezed
class RealEstateRequest with _$RealEstateRequest {
  const factory RealEstateRequest({
    required String name,
    String? description,
    required String type,
    required String province,
    required String district,
    required String neighborhood,
    required String address,
    int? tenantId,
    int? landlordId,
  }) = _RealEstateRequest;

  factory RealEstateRequest.fromJson(Map<String, dynamic> json) =>
      _$RealEstateRequestFromJson(json);
}
