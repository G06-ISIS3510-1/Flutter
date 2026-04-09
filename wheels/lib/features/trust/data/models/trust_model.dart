import '../../domain/entities/trust_entity.dart';

class TrustModel extends TrustEntity {
  const TrustModel({
    required super.userId,
    required super.role,
    required super.accountCreatedAt,
    required super.totalRides,
    required super.completedRides,
    required super.cancelledRides,
    required super.activeRides,
    required super.totalPayments,
    required super.approvedPayments,
    required super.pendingPayments,
    required super.failedPayments,
    required super.score,
    required super.rewardPoints,
  });

  factory TrustModel.fromJson(Map<String, dynamic> json) {
    return TrustModel(
      userId: (json['userId'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'passenger',
      accountCreatedAt:
          _readDateTime(json['accountCreatedAt']) ??
          _readDateTime(json['createdAt']) ??
          DateTime.now(),
      totalRides: _readInt(json['totalRides']),
      completedRides: _readInt(json['completedRides']),
      cancelledRides: _readInt(json['cancelledRides']),
      activeRides: _readInt(json['activeRides']),
      totalPayments: _readInt(json['totalPayments']),
      approvedPayments: _readInt(json['approvedPayments']),
      pendingPayments: _readInt(json['pendingPayments']),
      failedPayments: _readInt(json['failedPayments']),
      score: _readInt(json['score']),
      rewardPoints: _readInt(json['rewardPoints']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
