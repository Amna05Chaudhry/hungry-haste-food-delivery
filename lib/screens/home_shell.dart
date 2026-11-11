import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'favourites_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _MenuTab(),
      const FavouritesTab(),
      const OrdersTab(),
      ProfileTab(onBrowseMenu: () => setState(() => _tab = 0)),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favourites'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MenuTab extends StatefulWidget {
  const _MenuTab();
  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  String _query = '';
  String? _category; // null = all

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final items = state.menu.where((m) {
      final inCat = _category == null || m.category == _category;
      final match = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q);
      return inCat && match;
    }).toList();

    return MaxWidth(
      width: 1100,
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          sliver: SliverToBoxAdapter(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi ${state.user?.firstName.isNotEmpty == true ? state.user!.firstName : 'there'} 👋',
                      style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  Text('Delicious food for you',
                      style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                ]),
              ),
              const ModeBadge(),
              const CartButton(),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: SearchBar(
              hintText: 'Search dishes, drinks…',
              elevation: const WidgetStatePropertyAll(0),
              leading: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.search)),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () => setState(() => _query = ''),
                    icon: const Icon(Icons.close),
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                for (final c in [null, ...MenuItem.categories])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c ?? 'All'),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!state.menuLoaded)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (state.menuError != null)
          SliverFillRemaining(
            child: EmptyState(
              icon: Icons.cloud_off,
              title: "Couldn't load the menu",
              message: state.menuError!,
            ),
          )
        else if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.search_off,
              title: state.menu.isEmpty ? 'The menu is empty' : 'Item not found',
              message: state.menu.isEmpty
                  ? 'An admin can add dishes (or load the sample menu) from the admin panel.'
                  : 'Try a different keyword or category.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => MenuCard(item: items[i]),
            ),
          ),
      ]),
    );
  }
}
