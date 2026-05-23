enum HelpCategory { account, payments, rides, safety, drivers }

extension HelpCategoryX on HelpCategory {
  String get storageValue => switch (this) {
    HelpCategory.account => 'account',
    HelpCategory.payments => 'payments',
    HelpCategory.rides => 'rides',
    HelpCategory.safety => 'safety',
    HelpCategory.drivers => 'drivers',
  };

  String get label => switch (this) {
    HelpCategory.account => 'Account',
    HelpCategory.payments => 'Payments',
    HelpCategory.rides => 'Rides',
    HelpCategory.safety => 'Safety',
    HelpCategory.drivers => 'Drivers',
  };
}

HelpCategory helpCategoryFromStorage(String? rawValue) {
  switch (rawValue?.trim().toLowerCase()) {
    case 'account':
      return HelpCategory.account;
    case 'payments':
      return HelpCategory.payments;
    case 'safety':
      return HelpCategory.safety;
    case 'drivers':
      return HelpCategory.drivers;
    case 'rides':
    default:
      return HelpCategory.rides;
  }
}
