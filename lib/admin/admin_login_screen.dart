import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/seed_data.dart';
import '../screens/auth_screen.dart' show validateEmail;
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Separate entry point for restaurant staff: `/#/admin`.
/// Only accounts with `role: 'admin'` get through.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await state.signIn(_email.text, _password.text);
      if (!(state.user?.isAdmin ?? false)) {
        await state.signOut();
        throw 'This account is not an admin.';
      }
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.adminDashboard, (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final demo = context.read<AppState>().backend.isDemo;
    return Scaffold(
      backgroundColor: t.colorScheme.surfaceContainer,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: t.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _form,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: t.colorScheme.primaryContainer,
                        child: Icon(Icons.admin_panel_settings, color: t.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Hungry Haste Admin',
                              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          Text('Menu & order management',
                              style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Admin email', prefixIcon: Icon(Icons.mail_outline)),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Text('Sign in to admin'),
                    ),
                    if (demo) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () {
                                _email.text = DemoAccounts.adminEmail;
                                _password.text = DemoAccounts.adminPassword;
                                _login();
                              },
                        icon: const Icon(Icons.bolt),
                        label: const Text('Use demo admin account'),
                      ),
                      const SizedBox(height: 8),
                      Text('${DemoAccounts.adminEmail} · ${DemoAccounts.adminPassword}',
                          textAlign: TextAlign.center,
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.splash, (_) => false),
                      child: const Text('← Back to the customer app'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
