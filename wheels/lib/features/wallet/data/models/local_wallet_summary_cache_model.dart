import '../../domain/entities/wallet_summary.dart';
import 'wallet_summary_model.dart';

class LocalWalletSummaryCacheModel {
  const LocalWalletSummaryCacheModel({
    required this.version,
    required this.savedAt,
    required this.summary,
  });

  final int version;
  final DateTime savedAt;
  final WalletSummaryModel summary;

  factory LocalWalletSummaryCacheModel.create({
    required WalletSummary summary,
    DateTime? savedAt,
  }) {
    return LocalWalletSummaryCacheModel(
      version: 1,
      savedAt: savedAt ?? DateTime.now(),
      summary: WalletSummaryModel(
        availableBalance: summary.availableBalance,
        pendingWithdrawalBalance: summary.pendingWithdrawalBalance,
        totalEarned: summary.totalEarned,
      ),
    );
  }

  factory LocalWalletSummaryCacheModel.fromJson(Map<String, dynamic> json) {
    final version = (json['version'] as num?)?.toInt() ?? 1;
    if (version != 1) {
      throw FormatException('Unsupported wallet cache version: $version');
    }

    final savedAtRaw = json['savedAt'];
    final summaryRaw = json['summary'];

    if (savedAtRaw is! String || summaryRaw is! Map) {
      throw const FormatException('Stored wallet cache is invalid.');
    }

    final savedAt = DateTime.tryParse(savedAtRaw);
    if (savedAt == null) {
      throw const FormatException('Stored wallet cache has an invalid date.');
    }

    return LocalWalletSummaryCacheModel(
      version: version,
      savedAt: savedAt,
      summary: WalletSummaryModel.fromJson(
        Map<String, dynamic>.from(summaryRaw),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'savedAt': savedAt.toIso8601String(),
      'summary': summary.toJson(),
    };
  }

  WalletSummary toEntity() {
    return WalletSummary(
      availableBalance: summary.availableBalance,
      pendingWithdrawalBalance: summary.pendingWithdrawalBalance,
      totalEarned: summary.totalEarned,
    );
  }
}
