import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService.instance;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email and password.');
      return;
    }

    if (_mode == _AuthMode.signUp && name.isEmpty) {
      _showMessage('Enter your name to create an account.');
      return;
    }

    final ok = switch (_mode) {
      _AuthMode.signIn => await _auth.signIn(email: email, password: password),
      _AuthMode.signUp => await _auth.signUp(
        email: email,
        password: password,
        name: name,
      ),
    };

    if (!ok && mounted && _auth.error.isNotEmpty) return;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setMode(_AuthMode mode) {
    if (_mode == mode) return;
    _auth.clearError();
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final isSignUp = _mode == _AuthMode.signUp;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KineSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'KINE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: KineSpacing.sm),
                  Text(
                    'Athlete testing build',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                  const SizedBox(height: KineSpacing.xl),
                  Card(
                    color: colors.surfaceCard,
                    child: Padding(
                      padding: const EdgeInsets.all(KineSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 320;
                              final buttons = [
                                _ModeButton(
                                  label: 'Sign In',
                                  selected: _mode == _AuthMode.signIn,
                                  onPressed: () => _setMode(_AuthMode.signIn),
                                ),
                                _ModeButton(
                                  label: 'Create Account',
                                  selected: _mode == _AuthMode.signUp,
                                  onPressed: () => _setMode(_AuthMode.signUp),
                                ),
                              ];

                              if (narrow) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    buttons[0],
                                    const SizedBox(height: KineSpacing.sm),
                                    buttons[1],
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: buttons[0]),
                                  const SizedBox(width: KineSpacing.sm),
                                  Expanded(child: buttons[1]),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: KineSpacing.lg),
                          Text(
                            isSignUp
                                ? 'Create your athlete account'
                                : 'Sign in to continue',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: KineSpacing.sm),
                          Text(
                            isSignUp
                                ? 'Email confirmation is disabled for this testing build. New athlete accounts enter the app immediately.'
                                : 'Use your athlete email and password to access the app.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                          if (_auth.error.isNotEmpty) ...[
                            const SizedBox(height: KineSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(KineSpacing.inset),
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  KineRadius.md,
                                ),
                                border: Border.all(
                                  color: colors.error.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                _auth.error,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: KineSpacing.lg),
                          if (isSignUp) ...[
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _auth.clearError(),
                            ),
                            const SizedBox(height: KineSpacing.md),
                          ],
                          TextField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _auth.clearError(),
                          ),
                          const SizedBox(height: KineSpacing.md),
                          TextField(
                            controller: _passwordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => _auth.clearError(),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: KineSpacing.lg),
                          FilledButton(
                            onPressed: _auth.loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _auth.loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(isSignUp ? 'Create Account' : 'Sign In'),
                          ),
                        ],
                      ),
                    ),
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

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(label),
          );
  }
}
