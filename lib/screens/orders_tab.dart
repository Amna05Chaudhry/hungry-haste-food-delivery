import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'favourites_tab.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final uid = state.user?.uid;
    if (uid == null) return const SizedBox();
    return MaxWidth(
      child: StreamBuilder<List<FoodOrder>>(
        stream: state.backend.watchOrders(uid: uid),
        builder: (context, snap) {
          final orders = snap.data ?? const [];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TabHeader(title: 'My orders', subtitle: '${orders.length} orders'),
            Expanded(
              child: snap.hasError
                  ? EmptyState(icon: Icons.cloud_off, title: "Couldn't load orders", message: '${snap.error}')
                  : !snap.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : orders.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No orders yet',
                              message: 'Your order history will show up here.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: orders.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => OrderCard(order: orders[i]),
                            ),
            ),
          ]);
        },
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      OrderStatus.delivered => (Colors.green.withValues(alpha: 0.15), Colors.green.shade700),
      OrderStatus.cancelled => (scheme.errorContainer, scheme.onErrorContainer),
      OrderStatus.onTheWay => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(status.label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.trailing});
  final FoodOrder order;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(children: [
          Text('#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          StatusChip(order.status),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${DateFormat('d MMM, HH:mm').format(order.createdAt)} · '
            '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ${rupees(order.total)}',
          ),
        ),
        trailing: trailing,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final l in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Text('${l.quantity} × ${l.name}')),
                Text(rupees(l.price * l.quantity)),
              ]),
            ),
          const Divider(),
          Row(children: [
            Expanded(child: Text(order.delivery == DeliveryMethod.door ? 'Delivery fee' : 'Pick-up')),
            Text(rupees(order.deliveryFee)),
          ]),
          Row(children: [
            const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700))),
            Text(rupees(order.total), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${order.customerName} · ${order.address} · paid by ${order.payment.name}',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
