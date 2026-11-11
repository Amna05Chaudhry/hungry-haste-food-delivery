import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/seed_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart' show requiredField;

/// Delivery + payment on one page (the original app split them in two
/// screens with a hard-coded address; this uses the user's profile).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final AppUser _user = context.read<AppState>().user!;
  late final _address = TextEditingController(text: _user.address);
  late final _phone = TextEditingController(text: _user.phone);
  DeliveryMethod _delivery = DeliveryMethod.door;
  PaymentMethod _payment = PaymentMethod.cash;
  bool _busy = false;

  int get _fee => _delivery == DeliveryMethod.door ? doorDeliveryFee : 0;

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.receipt_long_outlined),
        title: const Text('Confirm order'),
        content: Text(
          'Total ${rupees(state.cartTotal + _fee)}, '
          '${_delivery == DeliveryMethod.door ? 'delivered to ${_address.text.trim()}' : 'for pick-up'}, '
          'paid by ${_payment.name}.'
          '${state.backend.isDemo ? '\n\nDemo mode: no real payment is taken.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Place order'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final order = await state.placeOrder(
        delivery: _delivery,
        payment: _payment,
        address: _address.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
          title: const Text('Order placed!'),
          content: Text('Order #${order.id} is being prepared. Track it in the Orders tab.'),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = Theme.of(context);
    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
          child: Text(title, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: MaxWidth(
        width: 640,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            section('Delivery method'),
            SegmentedButton<DeliveryMethod>(
              segments: const [
                ButtonSegment(value: DeliveryMethod.door, icon: Icon(Icons.delivery_dining), label: Text('Door delivery')),
                ButtonSegment(value: DeliveryMethod.pickup, icon: Icon(Icons.storefront), label: Text('Pick up')),
              ],
              selected: {_delivery},
              onSelectionChanged: (s) => setState(() => _delivery = s.first),
            ),
            section('Contact details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(user: _user, radius: 20),
                    title: Text(_user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_user.email),
                  ),
                  if (_delivery == DeliveryMethod.door) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Delivery address', prefixIcon: Icon(Icons.home_outlined)),
                      validator: (v) => requiredField(v, 'delivery address'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => requiredField(v, 'phone number'),
                  ),
                ]),
              ),
            ),
            section('Payment method'),
            Card(
              child: RadioGroup<PaymentMethod>(
                groupValue: _payment,
                onChanged: (v) => setState(() => _payment = v!),
                child: Column(children: [
                  _PaymentTile(PaymentMethod.cash, 'Cash on delivery', Icons.payments_outlined, Colors.green),
                  _PaymentTile(PaymentMethod.card, 'Card', Icons.credit_card, Colors.orange),
                  _PaymentTile(PaymentMethod.bank, 'Bank transfer', Icons.account_balance_outlined, Colors.pink),
                ]),
              ),
            ),
            section('Summary'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  for (final l in state.cart)
                    _Row('${l.quantity} × ${l.item.name}', rupees(l.subtotal)),
                  const Divider(height: 20),
                  _Row('Delivery', _fee == 0 ? 'Free' : rupees(_fee)),
                  const SizedBox(height: 4),
                  _Row('Total', rupees(state.cartTotal + _fee), bold: true),
                ]),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: MaxWidth(
          width: 640,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: _busy || state.cart.isEmpty ? null : _placeOrder,
              child: _busy
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text('Place order · ${rupees(state.cartTotal + _fee)}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile(this.value, this.title, this.icon, this.color);
  final PaymentMethod value;
  final String title;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => RadioListTile<PaymentMethod>(
        value: value,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title),
        ]),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400, fontSize: bold ? 17 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
    );
  }
}
