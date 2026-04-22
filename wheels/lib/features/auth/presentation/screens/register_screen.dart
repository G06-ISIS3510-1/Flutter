import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme_palette.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/validation/auth_input_constraints.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({this.initialModeIndex = 0, super.key});

  final int initialModeIndex;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  int _selectedModeIndex = 0;
  UserRole? _selectedRole = UserRole.passenger;
  bool _isRegisterLoading = false;
  bool _isLoginLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedModeIndex = widget.initialModeIndex.clamp(0, 1);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  bool get _isRegisterValid {
    return validatePersonalName(
              _firstNameController.text,
              fieldLabel: 'First name',
            ) ==
            null &&
        validatePersonalName(
              _lastNameController.text,
              fieldLabel: 'Last name',
            ) ==
            null &&
        _isValidUsername(_registerUsernameController.text) &&
        _registerPasswordController.text.length >= 6 &&
        _confirmPasswordController.text == _registerPasswordController.text &&
        _selectedRole != null;
  }

  bool get _isLoginValid {
    return _isValidUsername(_loginUsernameController.text) &&
        _loginPasswordController.text.length >= 6;
  }

  String get _constructedRegisterEmail {
    final username = _registerUsernameController.text.trim();
    return username.isEmpty ? '' : buildUniversityEmail(username);
  }

  String get _constructedLoginEmail {
    final username = _loginUsernameController.text.trim();
    return username.isEmpty ? '' : buildUniversityEmail(username);
  }

  bool _isValidUsername(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        !trimmed.contains(' ') &&
        !trimmed.contains('@');
  }

  Future<void> _submitRegister() async {
    final formState = _registerFormKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    if (_selectedRole == null) {
      _showSnackBar('Please choose Driver or Passenger before registering.');
      return;
    }

    setState(() {
      _isRegisterLoading = true;
    });

    try {
      final role = _selectedRole!;
      final authEntity = await ref
          .read(authRepositoryProvider)
          .registerWithUniversityEmail(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            username: _registerUsernameController.text.trim(),
            password: _registerPasswordController.text,
            role: _roleStorageValue(role),
          );

      if (!mounted) return;
      _completeAuth(authEntity, role);
      _showSnackBar('Welcome to Wheels, ${_firstNameController.text.trim()}!');
      context.go(AppRoutes.dashboard);
    } on AuthFailure catch (error) {
      _showSnackBar(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isRegisterLoading = false;
        });
      }
    }
  }

  Future<void> _submitLogin() async {
    final formState = _loginFormKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isLoginLoading = true;
    });

    try {
      final authEntity = await ref
          .read(authRepositoryProvider)
          .signInWithUniversityEmail(
            username: _loginUsernameController.text.trim(),
            password: _loginPasswordController.text,
          );

      if (!mounted) return;
      final role = authEntity.role == 'driver'
          ? UserRole.driver
          : authEntity.role == 'admin'
          ? UserRole.admin
          : UserRole.passenger;
      _completeAuth(authEntity, role);
      _showSnackBar('Welcome back!');
      context.go(AppRoutes.dashboard);
    } on AuthFailure catch (error) {
      _showSnackBar(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
      }
    }
  }

  void _completeAuth(AuthEntity authEntity, UserRole role) {
    ref.read(authUserProvider.notifier).state = authEntity;
    ref.read(currentUserRoleProvider.notifier).state = role;
  }

  void _continueWithDevAccess() {
    final role = _selectedRole ?? UserRole.passenger;
    _completeAuth(
      AuthEntity(
        uid: 'dev-user',
        email: 'dev@uniandes.edu.co',
        role: _roleStorageValue(role),
        fullName: 'Dev Access',
      ),
      role,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Dev access enabled. You can keep exploring the app.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.go(AppRoutes.dashboard);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  static String _roleStorageValue(UserRole role) {
    return role == UserRole.driver ? 'driver' : 'passenger';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthHeader(
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    title: 'University Access',
                    subtitle:
                        'Register with your Uniandes email to join the trusted student ride community.',
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const AuthInfoCard(),
                  const SizedBox(height: AppSpacing.l),
                  AuthFormShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthModeToggle(
                          selectedIndex: _selectedModeIndex,
                          onChanged: (index) {
                            setState(() {
                              _selectedModeIndex = index;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _selectedModeIndex == 0
                              ? RegisterForm(
                                  key: const ValueKey('register-form'),
                                  formKey: _registerFormKey,
                                  firstNameController: _firstNameController,
                                  lastNameController: _lastNameController,
                                  usernameController:
                                      _registerUsernameController,
                                  passwordController:
                                      _registerPasswordController,
                                  confirmPasswordController:
                                      _confirmPasswordController,
                                  selectedRole: _selectedRole,
                                  onRoleSelected: (role) {
                                    setState(() {
                                      _selectedRole = role;
                                    });
                                  },
                                  onChanged: () => setState(() {}),
                                  onSubmit: _submitRegister,
                                  isLoading: _isRegisterLoading,
                                  isValid: _isRegisterValid,
                                  constructedEmail: _constructedRegisterEmail,
                                )
                              : LoginForm(
                                  key: const ValueKey('login-form'),
                                  formKey: _loginFormKey,
                                  usernameController: _loginUsernameController,
                                  passwordController: _loginPasswordController,
                                  onChanged: () => setState(() {}),
                                  onSubmit: _submitLogin,
                                  isLoading: _isLoginLoading,
                                  isValid: _isLoginValid,
                                  constructedEmail: _constructedLoginEmail,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Need to reset your password?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        child: const Text('Forgot password'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Center(
                    child: DevAccessButton(onPressed: _continueWithDevAccess),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
