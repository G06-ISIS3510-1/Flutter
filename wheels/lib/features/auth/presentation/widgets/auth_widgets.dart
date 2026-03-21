import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../providers/auth_providers.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.onBack,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final VoidCallback onBack;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          style: TextButton.styleFrom(
            foregroundColor: palette.primary,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          ),
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          label: const Text(
            'Back',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        const Center(child: _AuthLogo()),
        const SizedBox(height: 22),
        Text(
          title,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Register',
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeButton(
              label: 'Login',
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthInfoCard extends StatelessWidget {
  const AuthInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Only @uniandes.edu.co accounts can register',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Type only your university username and we will complete the official Uniandes email for you automatically.',
            style: TextStyle(color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Your account will be created with Firebase Authentication and your profile will be saved securely in Firestore.',
              style: TextStyle(
                color: palette.accent,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UniversityEmailField extends StatelessWidget {
  const UniversityEmailField({
    required this.controller,
    required this.label,
    this.onChanged,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'raul.insuasty',
        prefixIcon: const Icon(Icons.alternate_email_rounded),
        suffixText: '@uniandes.edu.co',
        suffixStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    required this.selectedRole,
    required this.onSelected,
    super.key,
  });

  final UserRole? selectedRole;
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleOption(
            title: 'Driver',
            subtitle: 'Offer rides',
            icon: Icons.directions_car_outlined,
            isSelected: selectedRole == UserRole.driver,
            onTap: () => onSelected(UserRole.driver),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleOption(
            title: 'Passenger',
            subtitle: 'Book rides',
            icon: Icons.person_outline_rounded,
            isSelected: selectedRole == UserRole.passenger,
            onTap: () => onSelected(UserRole.passenger),
          ),
        ),
      ],
    );
  }
}

class RegisterForm extends StatelessWidget {
  const RegisterForm({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.onChanged,
    required this.onSubmit,
    required this.isLoading,
    required this.isValid,
    required this.constructedEmail,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final UserRole? selectedRole;
  final ValueChanged<UserRole> onRoleSelected;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isValid;
  final String constructedEmail;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: firstNameController,
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'First name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: _validateRequiredField,
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: lastNameController,
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Last name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: _validateRequiredField,
          ),
          const SizedBox(height: AppSpacing.m),
          UniversityEmailField(
            controller: usernameController,
            label: 'University email username',
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            validator: _validateUsername,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            constructedEmail.isEmpty
                ? 'Your university email will be: username@uniandes.edu.co'
                : 'Your university email will be: $constructedEmail',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: passwordController,
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: confirmPasswordController,
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please confirm your password';
              }
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            'Choose your role',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          RoleSelector(selectedRole: selectedRole, onSelected: onRoleSelected),
          if (selectedRole == null) ...[
            const SizedBox(height: 10),
            Text(
              'Select whether you want to join as a driver or passenger.',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: isLoading ? 'Creating account...' : 'Create account',
              onPressed: isValid && !isLoading ? onSubmit : null,
            ),
          ),
        ],
      ),
    );
  }

  static String? _validateRequiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your university username';
    }
    if (value.contains(' ')) {
      return 'Your username cannot contain spaces';
    }
    if (value.contains('@')) {
      return 'Type only the username, not the full email';
    }
    return null;
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a password';
    }
    if (value.length < 6) {
      return 'Use at least 6 characters';
    }
    return null;
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.onChanged,
    required this.onSubmit,
    required this.isLoading,
    required this.isValid,
    required this.constructedEmail,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isValid;
  final String constructedEmail;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UniversityEmailField(
            controller: usernameController,
            label: 'University email username',
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            validator: RegisterForm._validateUsername,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            constructedEmail.isEmpty
                ? 'You will sign in with: username@uniandes.edu.co'
                : 'You will sign in with: $constructedEmail',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: passwordController,
            enabled: !isLoading,
            onChanged: (_) => onChanged(),
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator: RegisterForm._validatePassword,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: isLoading ? 'Signing in...' : 'Login',
              onPressed: isValid && !isLoading ? onSubmit : null,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.lg,
      ),
      child: child,
    );
  }
}

class DevAccessButton extends StatelessWidget {
  const DevAccessButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: palette.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: const Icon(Icons.code_rounded, size: 18),
      label: const Text(
        'Dev access',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.xl,
      ),
      child: const Icon(Icons.verified_user_outlined, color: AppColors.accent),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? palette.primaryForeground
                : palette.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? palette.accentSoft : palette.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? palette.accent.withValues(alpha: 0.4)
                : palette.border,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.accent.withValues(alpha: 0.16)
                    : palette.cardSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.accentHover : palette.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
