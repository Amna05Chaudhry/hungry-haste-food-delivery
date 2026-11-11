import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

class FavouritesTab extends StatelessWidget {
  const FavouritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<AppState>().favourites;
    return MaxWidth(
      width: 1100,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabHeader(title: 'Favourites', subtitle: '${favs.length} saved'),
        Expanded(
          child: favs.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'No favourites yet',
                  message: 'Tap the heart on any dish to save it here.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: favs.length,
                  itemBuilder: (_, i) => MenuCard(item: favs[i], hero: false),
                ),
        ),
      ]),
    );
  }
}

class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text(subtitle, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
        const CartButton(),
      ]),
    );
  }
}

