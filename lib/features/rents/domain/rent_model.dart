import 'package:freezed_annotation/freezed_annotation.dart';

part 'rent_model.freezed.dart';
part 'rent_model.g.dart';

@freezed
class Rent with _$Rent {
  const factory Rent({
    required int id,
    required int realEstateId,
    required String realEstateName,
    required String rentDate,
    required double rentAmount,
    required String currency,
    double? increaseRate,
    required String status,
    required String createdDate,
    required String createdBy,
  }) = _Rent;

  factory Rent.fromJson(Map<String, dynamic> json) => _$RentFromJson(json);
}

@freezed
class RentRequest with _$RentRequest {
  const factory RentRequest({
    required int realEstateId,
    required String rentDate,
    required double rentAmount,
    required String currency,
    double? increaseRate,
  }) = _RentRequest;

  factory RentRequest.fromJson(Map<String, dynamic> json) =>
      _$RentRequestFromJson(json);
}
