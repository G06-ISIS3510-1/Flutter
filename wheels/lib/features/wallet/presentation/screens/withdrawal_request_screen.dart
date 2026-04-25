import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/ui/app_scaffold.dart';
import '../../../../shared/utils/app_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/withdrawal_request_input.dart';
import '../../domain/entities/wallet_summary.dart';
import '../providers/wallet_providers.dart';

class WithdrawalRequestScreen extends ConsumerStatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  ConsumerState<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState
    extends ConsumerState<WithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  String _accountType = 'savings';

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authUserProvider);
    final role = ref.watch(currentUserRoleProvider);
    final walletSummaryAsync = ref.watch(driverWalletSummaryProvider);
    final requestState = ref.watch(withdrawalRequestControllerProvider);
    final isLoading = requestState.isLoading;

    ref.listen<AsyncValue<WithdrawalRequestResult?>>(
      withdrawalRequestControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (result) {
            if (!(previous?.isLoading ?? false) || result == null || !mounted) {
              return;
            }

            ref.read(withdrawalRequestControllerProvider.notifier).clear();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    result.message ??
                        'Withdrawal request created successfully.',
                  ),
                ),
              );
            context.pop();
          },
          error: (error, _) {
            if (!(previous?.isLoading ?? false) || !mounted) {
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    error.toString().replaceFirst('Exception: ', ''),
                  ),
                ),
              );
          },
        );
      },
    );

    return AppScaffold(
      title: 'Request Withdrawal',
      child: currentUser == null || role != UserRole.driver
          ? const _WithdrawalAccessCard()
          : walletSummaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _WithdrawalLoadErrorCard(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(driverWalletSummaryProvider),
              ),
              data: (walletSummary) {
                if (walletSummary == null) {
                  return const _WithdrawalAccessCard();
                }

                return SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WithdrawalInfoCard(walletSummary: walletSummary),
                        const SizedBox(height: AppSpacing.l),
                        _FormTextField(
                          controller: _amountController,
                          label: 'Amount',
                          hintText: '10000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            final amount = _parseAmount(value);
                            if (amount == null) {
                              return 'Enter a valid amount.';
                            }
                            if (amount < walletMinimumWithdrawalAmountCop) {
                              return 'Minimum withdrawal is COP 10.000.';
                            }
                            if (amount > walletSummary.availableBalance) {
                              return 'Amount exceeds your available balance.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _FormTextField(
                          controller: _bankNameController,
                          label: 'Bank name',
                          hintText: 'Bancolombia',
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the bank name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        DropdownButtonFormField<String>(
                          initialValue: _accountType,
                          decoration: _inputDecoration('Account type'),
                          items: const [
                            DropdownMenuItem(
                              value: 'savings',
                              child: Text('Savings'),
                            ),
                            DropdownMenuItem(
                              value: 'checking',
                              child: Text('Checking'),
                            ),
                          ],
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _accountType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _FormTextField(
                          controller: _accountNumberController,
                          label: 'Account number',
                          hintText: '0123456789',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the account number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _FormTextField(
                          controller: _accountHolderNameController,
                          label: 'Account holder name',
                          hintText: 'Full legal name',
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the account holder name.';
                            }
                            return null;
                          },
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: AppSpacing.m),
                          const LinearProgressIndicator(),
                        ],
                        const SizedBox(height: AppSpacing.l),
                        AppButton(
                          label: isLoading
                              ? 'Submitting withdrawal...'
                              : 'Submit withdrawal request',
                          onPressed: isLoading || !walletSummary.canRequestWithdrawal
                              ? null
                              : () => _submit(userId: currentUser.uid, walletSummary: walletSummary),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        AppButton(
                          label: 'Back',
                          onPressed: isLoading ? null : () => context.pop(),
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _submit({
    required String userId,
    required WalletSummary walletSummary,
  }) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount == null) {
      return;
    }
    if (amount > walletSummary.availableBalance) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Amount exceeds your available balance.'),
          ),
        );
      return;
    }

    await ref
        .read(withdrawalRequestControllerProvider.notifier)
        .submit(
          userId: userId,
          amount: amount,
          bankName: _bankNameController.text,
          accountType: _accountType,
          accountNumber: _accountNumberController.text,
          accountHolderName: _accountHolderNameController.text,
        );
  }

  int? _parseAmount(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }
    return int.tryParse(rawValue.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  InputDecoration _inputDecoration(String label) {
    final palette = context.palette;

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: palette.input,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: palette.primary),
      ),
    );
  }
}

class _WithdrawalInfoCard extends StatelessWidget {
  const _WithdrawalInfoCard({required this.walletSummary});

  final WalletSummary? walletSummary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: palette.secondarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Withdrawal request',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Available balance: ${AppFormatter.cop(walletSummary?.availableBalance ?? 0)}\nMinimum withdrawal: COP 10.000.\nOnly one pending withdrawal request is allowed per driver, and requests are processed manually later.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: palette.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.primary),
        ),
      ),
    );
  }
}

class _WithdrawalAccessCard extends StatelessWidget {
  const _WithdrawalAccessCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 42,
              color: palette.primary,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Driver access required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Sign in with a driver account to submit withdrawal requests.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawalLoadErrorCard extends StatelessWidget {
  const _WithdrawalLoadErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.error),
            const SizedBox(height: AppSpacing.m),
            Text(
              'We could not load the wallet balance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.m),
            AppButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
