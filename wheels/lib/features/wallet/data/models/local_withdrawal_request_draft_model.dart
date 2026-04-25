class LocalWithdrawalRequestDraftModel {
  const LocalWithdrawalRequestDraftModel({
    required this.version,
    required this.savedAt,
    required this.amountText,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.accountHolderName,
  });

  final int version;
  final DateTime savedAt;
  final String amountText;
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String accountHolderName;

  factory LocalWithdrawalRequestDraftModel.create({
    required String amountText,
    required String bankName,
    required String accountType,
    required String accountNumber,
    required String accountHolderName,
    DateTime? savedAt,
  }) {
    return LocalWithdrawalRequestDraftModel(
      version: 1,
      savedAt: savedAt ?? DateTime.now(),
      amountText: amountText,
      bankName: bankName,
      accountType: accountType,
      accountNumber: accountNumber,
      accountHolderName: accountHolderName,
    );
  }

  factory LocalWithdrawalRequestDraftModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final version = (json['version'] as num?)?.toInt() ?? 1;
    if (version != 1) {
      throw FormatException('Unsupported withdrawal draft version: $version');
    }

    final savedAtRaw = json['savedAt'];
    if (savedAtRaw is! String) {
      throw const FormatException(
        'Stored withdrawal draft has an invalid saved date.',
      );
    }

    final savedAt = DateTime.tryParse(savedAtRaw);
    if (savedAt == null) {
      throw const FormatException(
        'Stored withdrawal draft has an invalid saved date.',
      );
    }

    return LocalWithdrawalRequestDraftModel(
      version: version,
      savedAt: savedAt,
      amountText: (json['amountText'] as String?) ?? '',
      bankName: (json['bankName'] as String?) ?? '',
      accountType: (json['accountType'] as String?) ?? 'savings',
      accountNumber: (json['accountNumber'] as String?) ?? '',
      accountHolderName: (json['accountHolderName'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'savedAt': savedAt.toIso8601String(),
      'amountText': amountText,
      'bankName': bankName,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
    };
  }

  bool get hasMeaningfulData =>
      amountText.trim().isNotEmpty ||
      bankName.trim().isNotEmpty ||
      accountNumber.trim().isNotEmpty ||
      accountHolderName.trim().isNotEmpty;
}
