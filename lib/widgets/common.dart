import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Shows a bundled asset (`asset:...`) or a network image, with a neutral
/// placeholder while loading or on error.
class FoodImage extends StatelessWidget {
  const FoodImage(this.source, {super.key, this.fit = BoxFit.cover});
  final String source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.outline),
    );
    if (source.startsWith('asset:')) {
      return Image.asset(source.substring(6), fit: fit,
          errorBuilder: (_, _, _) => placeholder);
    }
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
      );
    }
    return placeholder;
  }
}

/// Circle avatar from a URL, a data: URI (demo uploads) or the user's initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 28});
  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = user.imageUrl;
    ImageProvider? image;
    if (url != null && url.startsWith('data:')) {
      image = MemoryImage(base64Decode(url.substring(url.indexOf(',') + 1)));
    } else if (url != null && url.startsWith('http')) {
      image = NetworkImage(url);
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: image,
      child: Text(user.initials,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer, fontSize: radius * 0.7)),
    );
  }
}

/// Small pill that tells viewers the app is running on local demo data.
class ModeBadge extends StatelessWidget {
  const ModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final demo = state.backend.isDemo;
    return Tooltip(
      message: demo
          ? 'Running on local demo data (no Firebase). Data is stored in this browser.'
          : 'Connected to Firebase',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: demo ? scheme.tertiaryContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(demo ? Icons.science_outlined : Icons.cloud_done_outlined,
              size: 14, color: demo ? scheme.onTertiaryContainer : scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(state.backend.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: demo ? scheme.onTertiaryContainer : scheme.onSecondaryContainer)),
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: t.colorScheme.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: t.colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ]),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 1});
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Decrease',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: Icon(Icons.remove, size: 18, color: scheme.onPrimary),
        ),
        Text('$value', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700)),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Increase',
          onPressed: value < 99 ? () => onChanged(value + 1) : null,
          icon: Icon(Icons.add, size: 18, color: scheme.onPrimary),
        ),
      ]),
    );
  }
}

/// Menu tile used on the home grid, favourites and search results.
class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.item, this.hero = true});
  final MenuItem item;

  /// Only one tab may own the hero tag (IndexedStack keeps all tabs alive).
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final state = context.watch<AppState>();
    final fav = state.isFavourite(item.id);
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/item?id=${Uri.encodeQueryComponent(item.id)}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              hero ? Hero(tag: 'food-${item.id}', child: FoodImage(item.image)) : FoodImage(item.image),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton.filledTonal(
                  tooltip: fav ? 'Remove from favourites' : 'Add to favourites',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => state.toggleFavourite(item.id),
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: fav ? t.colorScheme.primary : null),
                ),
              ),
              if (!item.available)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const Text('Sold out',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(rupees(item.price),
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: t.colorScheme.primary, fontWeight: FontWeight.w700)),
                ]),
              ),
              IconButton.filled(
                tooltip: 'Add to cart',
                visualDensity: VisualDensity.compact,
                onPressed: item.available
                    ? () {
                        state.addToCart(item.id);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text('${item.name} added to cart'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                                label: 'View cart',
                                onPressed: () => Navigator.pushNamed(context, '/cart')),
                          ));
                      }
                    : null,
                icon: const Icon(Icons.add, size: 20),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Cart button with a count badge, for app bars.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<AppState, int>((s) => s.cartCount);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => Navigator.pushNamed(context, '/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$error'),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
}

/// Centers content and caps its width so the phone-first layout looks
/// right in a desktop browser.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.width = 720});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: width), child: child),
      );
}
