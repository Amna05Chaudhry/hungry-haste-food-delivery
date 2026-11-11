import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

String? validateEmail(String? v) {
  final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$').hasMatch((v ?? '').trim());
  return ok ? null : 'Enter a valid email address';
}

String? validatePassword(String? v) =>
    (v ?? '').length >= 6 ? null : 'Password must be at least 6 characters';

String? requiredField(String? v, String label) => (v ?? '').trim().isEmpty ? 'Enter your $label' : null;

/// Login / Sign-up tabs (same structure as the original app).
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: MaxWidth(
            width: 480,
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 28),
                decoration: BoxDecoration(
                  color: t.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
                ),
                child: Column(children: [
                  Image.asset('assets/images/Bella2.png', height: 96),
                  const SizedBox(height: 8),
                  const ModeBadge(),
                  const SizedBox(height: 8),
                  const TabBar(
                    tabs: [Tab(text: 'Login'), Tab(text: 'Sign-up')],
                    labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ]),
              ),
              const Expanded(child: TabBarView(children: [_LoginForm(), _SignupForm()])),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset('assets/images/google.png', height: 20),
        label: const Text('Continue with Google'),
      );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final state = context.read<AppState>();
    final ctrl = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("We'll email you a link to choose a new password."),
          const SizedBox(height: 16),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Email')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (email == null || !mounted) return;
    if (validateEmail(email) != null) return showError(context, 'Enter a valid email address');
    try {
      await state.backend.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.backend.isDemo
            ? 'Demo mode: no email is sent. Use the demo account below.'
            : 'Reset link sent to $email'),
      ));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final t = Theme.of(context);
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(24), children: [
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
          validator: validateEmail,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
          validator: validatePassword,
          onFieldSubmitted: (_) => _submit(state),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : () => _submit(state),
          child: _busy
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Login'),
        ),
        const SizedBox(height: 12),
        _GoogleButton(onPressed: _busy ? null : () => _run(state.signInWithGoogle)),
        if (state.backend.isDemo) ...[
          const SizedBox(height: 24),
          Card(
            color: t.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            child: ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('Try the demo account'),
              subtitle: const Text('${DemoAccounts.customerEmail} · ${DemoAccounts.customerPassword}'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: _busy
                  ? null
                  : () {
                      _email.text = DemoAccounts.customerEmail;
                      _password.text = DemoAccounts.customerPassword;
                      _submit(state);
                    },
            ),
          ),
        ],
      ]),
    );
  }

  void _submit(AppState state) {
    if (!_form.currentState!.validate()) return;
    _run(() => state.signIn(_email.text, _password.text));
  }
}

class _SignupForm extends StatefulWidget {
  const _SignupForm();
  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(24), children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _first,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (v) => requiredField(v, 'first name'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _last,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (v) => requiredField(v, 'last name'),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
          validator: validateEmail,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
          validator: validatePassword,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _address,
          decoration: const InputDecoration(labelText: 'Delivery address', prefixIcon: Icon(Icons.home_outlined)),
          validator: (v) => requiredField(v, 'address'),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy
              ? null
              : () {
                  if (!_form.currentState!.validate()) return;
                  _run(() => state.signUp(
                        email: _email.text,
                        password: _password.text,
                        firstName: _first.text,
                        lastName: _last.text,
                        address: _address.text,
                        phone: _phone.text,
                      ));
                },
          child: _busy
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Create account'),
        ),
        const SizedBox(height: 12),
        _GoogleButton(onPressed: _busy ? null : () => _run(state.signInWithGoogle)),
      ]),
    );
  }
}
