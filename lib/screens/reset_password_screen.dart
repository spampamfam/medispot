import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String _statusMessage = '';
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _showSuccessMessage = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _showSuccessMessage = false;
    });

    try {
      // Verify current credentials first
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _currentPasswordController.text.trim(),
      );

      // Update password
      await userCredential.user
          ?.updatePassword(_newPasswordController.text.trim());

      setState(() {
        _statusMessage = 'password_updated_successfully'.tr();
        _showSuccessMessage = true;
      });

      // Clear form and return after delay
      _formKey.currentState?.reset();
      await Future.delayed(Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      setState(() {
        _statusMessage = 'error_unexpected'.tr();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorKey;
    switch (e.code) {
      case 'wrong-password':
        errorKey = 'error_wrong_password';
        break;
      case 'user-not-found':
        errorKey = 'error_user_not_found';
        break;
      case 'network-request-failed':
        errorKey = 'error_network';
        break;
      case 'requires-recent-login':
        errorKey = 'error_recent_login_required';
        break;
      default:
        errorKey = 'error_reset_password_failed';
    }
    setState(() => _statusMessage = errorKey.tr());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('reset_password'.tr()),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primaryContainer,
              colors.secondaryContainer,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Section
                        Icon(
                          Icons.lock_reset,
                          size: 72,
                          color: colors.primary,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'reset_password_title'.tr(),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'email'.tr(),
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'error_empty_email'.tr()
                              : value!.contains('@')
                                  ? null
                                  : 'error_invalid_email'.tr(),
                        ),
                        SizedBox(height: 16),

                        // Current Password Field
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          decoration: InputDecoration(
                            labelText: 'current_password'.tr(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureCurrentPassword =
                                      !_obscureCurrentPassword),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'error_empty_password'.tr()
                              : null,
                        ),
                        SizedBox(height: 16),

                        // New Password Field
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'new_password'.tr(),
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureNewPassword = !_obscureNewPassword),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'error_empty_password'.tr();
                            }
                            if (value!.length < 6) {
                              return 'error_weak_password'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),

                        // Status Message
                        if (_statusMessage.isNotEmpty)
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _showSuccessMessage
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showSuccessMessage
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _showSuccessMessage
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _statusMessage,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: _showSuccessMessage
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _resetPassword,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'reset_password'.tr(),
                                    style: textTheme.labelLarge,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
