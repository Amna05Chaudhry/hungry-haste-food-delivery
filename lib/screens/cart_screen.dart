import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = Theme.of(context);
    final lines = state.cart;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: MaxWidth(
        width: 640,
        child: lines.isEmpty
            ? EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Add something tasty from the menu.',
                action: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Start ordering'),
                ),
              )
            : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                Row(children: [
                  Icon(Icons.swipe_left_outlined, size: 18, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Swipe an item left to remove it',
                      style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 12),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(line.item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                            color: t.colorScheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.delete_outline, color: t.colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) {
                        state.setQuantity(line.item.id, 0);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text('${line.item.name} removed'),
                            action: SnackBarAction(
                                label: 'Undo', onPressed: () => state.setQuantity(line.item.id, line.quantity)),
                          ));
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(width: 72, height: 72, child: FoodImage(line.item.image)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(line.item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(rupees(line.subtotal),
                                    style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              QuantityStepper(
                                value: line.quantity,
                                onChanged: (v) => state.setQuantity(line.item.id, v),
                              ),
                              IconButton(
                                tooltip: state.isFavourite(line.item.id) ? 'Unfavourite' : 'Save to favourites',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => state.toggleFavourite(line.item.id),
                                icon: Icon(state.isFavourite(line.item.id) ? Icons.favorite : Icons.favorite_border,
                                    size: 20),
                              ),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ]),
      ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              child: MaxWidth(
                width: 640,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Text('Subtotal (${state.cartCount} items)', style: t.textTheme.titleMedium),
                      const Spacer(),
                      Text(rupees(state.cartTotal),
                          style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.checkout),
                      child: const Text('Complete order'),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}
