import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key, required this.itemId});
  final String itemId;
  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = Theme.of(context);
    final item = state.itemById(widget.itemId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: state.menuLoaded
            ? const EmptyState(
                icon: Icons.no_food_outlined,
                title: 'Dish not found',
                message: 'It may have been removed from the menu.',
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final fav = state.isFavourite(item.id);
    final inCart = state.quantityOf(item.id);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: fav ? 'Remove from favourites' : 'Add to favourites',
            onPressed: () => state.toggleFavourite(item.id),
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? t.colorScheme.primary : null),
          ),
          const CartButton(),
        ],
      ),
      body: MaxWidth(
        width: 640,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Hero(tag: 'food-${item.id}', child: FoodImage(item.image)),
            ),
          ),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.category.toUpperCase(),
                    style: t.textTheme.labelMedium
                        ?.copyWith(color: t.colorScheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.name, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
            Text(rupees(item.price),
                style: t.textTheme.headlineSmall?.copyWith(color: t.colorScheme.primary, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          Text(item.description.isEmpty ? 'Freshly prepared to order.' : item.description,
              style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 20),
          _InfoTile(
            icon: Icons.delivery_dining_outlined,
            title: 'Delivery info',
            text: 'Delivered in 30–45 minutes, 11am–11pm. Flat delivery fee ${rupees(doorDeliveryFee)}, '
                'or pick it up for free.',
          ),
          const SizedBox(height: 10),
          const _InfoTile(
            icon: Icons.verified_outlined,
            title: 'Return policy',
            text: 'Every order is checked before it leaves the kitchen. If something is wrong, '
                'contact us within 30 minutes for a replacement or refund.',
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: MaxWidth(
          width: 640,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              QuantityStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: item.available
                      ? () {
                          state.addToCart(item.id, _qty);
                          Navigator.pushNamed(context, Routes.cart);
                        }
                      : null,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(item.available
                      ? 'Add ${rupees(item.price * _qty)}${inCart > 0 ? '  ·  $inCart in cart' : ''}'
                      : 'Sold out'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: t.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(text)),
      ),
    );
  }
}
