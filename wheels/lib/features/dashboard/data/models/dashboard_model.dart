import '../../domain/entities/dashboard_entity.dart';
import '../../../rides/data/models/local_ride_details_cache_model.dart';
import '../../../rides/domain/entities/rides_entity.dart';
import '../../../wallet/domain/entities/wallet_summary.dart';

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.savedAt,
    required super.summary,
    required super.stats,
    required super.primaryUpdate,
    super.currentRide,
    super.walletSummary,
  });

  static const int currentVersion = 1;

  factory DashboardModel.create({
    required String summary,
    required DashboardStatsEntity stats,
    required DashboardUpdateEntity primaryUpdate,
    RidesEntity? currentRide,
    WalletSummary? walletSummary,
  }) {
    return DashboardModel(
      savedAt: DateTime.now().toUtc(),
      summary: summary,
      stats: stats,
      primaryUpdate: primaryUpdate,
      currentRide: currentRide,
      walletSummary: walletSummary,
    );
  }

  factory DashboardModel.fromEntity(DashboardEntity entity) {
    return DashboardModel(
      savedAt: entity.savedAt,
      summary: entity.summary,
      stats: entity.stats,
      primaryUpdate: entity.primaryUpdate,
      currentRide: entity.currentRide,
      walletSummary: entity.walletSummary,
    );
  }

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final version = _readRequiredInt(json['version'], 'version');
    if (version != currentVersion) {
      throw FormatException('Unsupported dashboard cache version: $version');
    }

    final rawStats = json['stats'];
    final rawPrimaryUpdate = json['primaryUpdate'];
    if (rawStats is! Map || rawPrimaryUpdate is! Map) {
      throw const FormatException('Dashboard cache is invalid.');
    }

    final rawCurrentRide = json['currentRide'];
    final rawWalletSummary = json['walletSummary'];

    return DashboardModel(
      savedAt: _parseRequiredDateTime(json['savedAt'], 'savedAt'),
      summary: _readRequiredString(json['summary'], 'summary'),
      stats: DashboardStatsEntity(
        ridesValue: _readRequiredString(rawStats['ridesValue'], 'ridesValue'),
        scoreValue: _readRequiredString(rawStats['scoreValue'], 'scoreValue'),
        ratingValue: _readRequiredString(rawStats['ratingValue'], 'ratingValue'),
      ),
      primaryUpdate: DashboardUpdateEntity(
        title: _readRequiredString(rawPrimaryUpdate['title'], 'title'),
        subtitle: _readRequiredString(rawPrimaryUpdate['subtitle'], 'subtitle'),
        actionKind: _dashboardActionKindFromStorage(
          _readRequiredString(rawPrimaryUpdate['actionKind'], 'actionKind'),
        ),
        actionLabel: _readOptionalString(rawPrimaryUpdate['actionLabel']),
        rideId: _readOptionalString(rawPrimaryUpdate['rideId']),
        trailing: _readOptionalString(rawPrimaryUpdate['trailing']),
      ),
      currentRide: rawCurrentRide is Map
          ? LocalRideDetailsModel.fromJson(
              Map<String, dynamic>.from(rawCurrentRide),
            ).toEntity()
          : null,
      walletSummary: rawWalletSummary is Map
          ? WalletSummary(
              availableBalance: _readRequiredDouble(
                rawWalletSummary['availableBalance'],
                'availableBalance',
              ),
              pendingWithdrawalBalance: _readRequiredDouble(
                rawWalletSummary['pendingWithdrawalBalance'],
                'pendingWithdrawalBalance',
              ),
              totalEarned: _readRequiredDouble(
                rawWalletSummary['totalEarned'],
                'totalEarned',
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': currentVersion,
      'savedAt': savedAt.toIso8601String(),
      'summary': summary,
      'stats': <String, dynamic>{
        'ridesValue': stats.ridesValue,
        'scoreValue': stats.scoreValue,
        'ratingValue': stats.ratingValue,
      },
      'primaryUpdate': <String, dynamic>{
        'title': primaryUpdate.title,
        'subtitle': primaryUpdate.subtitle,
        'actionKind': primaryUpdate.actionKind.storageValue,
        'actionLabel': primaryUpdate.actionLabel,
        'rideId': primaryUpdate.rideId,
        'trailing': primaryUpdate.trailing,
      },
      'currentRide': currentRide == null
          ? null
          : LocalRideDetailsModel.fromEntity(currentRide!).toJson(),
      'walletSummary': walletSummary == null
          ? null
          : <String, dynamic>{
              'availableBalance': walletSummary!.availableBalance,
              'pendingWithdrawalBalance':
                  walletSummary!.pendingWithdrawalBalance,
              'totalEarned': walletSummary!.totalEarned,
            },
    };
  }
}

extension DashboardActionKindStorage on DashboardActionKind {
  String get storageValue => switch (this) {
    DashboardActionKind.none => 'none',
    DashboardActionKind.searchRides => 'search_rides',
    DashboardActionKind.createRide => 'create_ride',
    DashboardActionKind.openRide => 'open_ride',
    DashboardActionKind.openPayment => 'open_payment',
    DashboardActionKind.openWallet => 'open_wallet',
  };
}

DashboardActionKind _dashboardActionKindFromStorage(String rawValue) {
  switch (rawValue.trim().toLowerCase()) {
    case 'search_rides':
      return DashboardActionKind.searchRides;
    case 'create_ride':
      return DashboardActionKind.createRide;
    case 'open_ride':
      return DashboardActionKind.openRide;
    case 'open_payment':
      return DashboardActionKind.openPayment;
    case 'open_wallet':
      return DashboardActionKind.openWallet;
    case 'none':
    default:
      return DashboardActionKind.none;
  }
}

String _readRequiredString(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }

  return rawValue;
}

String? _readOptionalString(Object? rawValue) {
  if (rawValue == null) {
    return null;
  }

  if (rawValue is! String) {
    throw const FormatException('Invalid optional string value.');
  }

  return rawValue;
}

int _readRequiredInt(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toInt();
  }

  throw FormatException('Invalid $fieldName value.');
}

double _readRequiredDouble(Object? rawValue, String fieldName) {
  if (rawValue is num) {
    return rawValue.toDouble();
  }

  throw FormatException('Invalid $fieldName value.');
}

DateTime _parseRequiredDateTime(Object? rawValue, String fieldName) {
  if (rawValue is! String) {
    throw FormatException('Invalid $fieldName value.');
  }

  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) {
    throw FormatException('Invalid $fieldName value.');
  }

  return parsed;
}
