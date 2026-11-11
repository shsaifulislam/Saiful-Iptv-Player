import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../services/auth/auth_provider.dart';

enum AuthMode { signIn, signUp }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = ref.read(authServiceProvider);
    if (authService == null) {
      setState(() {
        _errorMessage =
            'Cloud backend is not configured in this build. Please configure SUPABASE_URL and SUPABASE_ANON_KEY.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_mode == AuthMode.signIn) {
        final result = await authService.signIn(email: email, password: password);
        result.when(
          success: (user) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${user.email}!'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go(RouteNames.profile);
            }
          },
          failure: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = error.message;
              });
            }
          },
        );
      } else {
        final result = await authService.signUp(email: email, password: password);
        result.when(
          success: (user) {
            if (mounted) {
              setState(() {
                _infoMessage =
                    'Account created successfully! Check your email to confirm your account or sign in now.';
                _mode = AuthMode.signIn;
              });
            }
          },
          failure: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = error.message;
              });
            }
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isResetting = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset password'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your registered email address and we will send you a password recovery link.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email.';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isResetting = true;
                            dialogError = null;
                          });

                          final authService = ref.read(authServiceProvider);
                          if (authService == null) {
                            setDialogState(() {
                              isResetting = false;
                              dialogError = 'Cloud services not configured.';
                            });
                            return;
                          }

                          final email = resetEmailController.text.trim();
                          final result =
                              await authService.resetPassword(email: email);
                          result.when(
                            success: (_) {
                              Navigator.of(context).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Password reset email sent. Please check your inbox.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            failure: (error) {
                              setDialogState(() {
                                isResetting = false;
                                dialogError = error.message;
                              });
                            },
                          );
                        },
                  child: isResetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send recovery email'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCloudConfigured = AppConfig.instance.isCloudConfigured;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: const Icon(
                            Icons.cloud_sync_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _mode == AuthMode.signIn
                                    ? 'Sign In to Saiful IPTV'
                                    : 'Create an Account',
                                style: AppTypography.headlineSmall,
                              ),
                              Text(
                                _mode == AuthMode.signIn
                                    ? 'Sync your playlists, watch history and settings'
                                    : 'Cross-device cloud synchronization',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (!isCloudConfigured)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            const Expanded(
                              child: Text(
                                'Cloud services are not configured in this build. Local storage and offline mode remain active.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Mode switch
                    SegmentedButton<AuthMode>(
                      segments: const [
                        ButtonSegment(
                          value: AuthMode.signIn,
                          label: Text('Sign In'),
                          icon: Icon(Icons.login),
                        ),
                        ButtonSegment(
                          value: AuthMode.signUp,
                          label: Text('Register'),
                          icon: Icon(Icons.person_add_outlined),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) =>
                          _switchMode(selection.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_infoMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _infoMessage!,
                                style: const TextStyle(
                                    color: AppColors.success, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email.';
                        }
                        final trimmed = value.trim();
                        if (!trimmed.contains('@') || !trimmed.contains('.')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: _mode == AuthMode.signUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted:
                          _mode == AuthMode.signIn ? (_) => _submit() : null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        if (_mode == AuthMode.signUp && value.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        }
                        return null;
                      },
                    ),

                    if (_mode == AuthMode.signUp) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (_mode == AuthMode.signIn) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _showPasswordResetDialog,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.md),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _mode == AuthMode.signIn
                                  ? 'Sign In'
                                  : 'Create Account',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

