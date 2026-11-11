import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/models.dart';
import '../screens/orders_tab.dart' show OrderCard, StatusChip;
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Web admin panel: dashboard, menu CRUD and order management.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  static const _destinations = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    (Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Menu'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final body = switch (_tab) {
      0 => _Dashboard(onOpen: (i) => setState(() => _tab = i)),
      1 => const _MenuAdmin(),
      _ => const _OrdersAdmin(),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hungry Haste · Admin'),
        actions: [
          const ModeBadge(),
          const SizedBox(width: 8),
          if (state.user != null)
            Padding(padding: const EdgeInsets.only(right: 4), child: UserAvatar(user: state.user!, radius: 16)),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await state.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.admin, (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide)
          NavigationRail(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final (icon, sel, label) in _destinations)
                NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(sel), label: Text(label)),
            ],
          ),
        Expanded(child: body),
      ]),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final (icon, sel, label) in _destinations)
                  NavigationDestination(icon: Icon(icon), selectedIcon: Icon(sel), label: label),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------- dashboard
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onOpen});
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = Theme.of(context);
    return StreamBuilder<List<FoodOrder>>(
      stream: state.backend.watchOrders(),
      builder: (context, snap) {
        final orders = snap.data ?? const <FoodOrder>[];
        final today = DateTime.now();
        final todays = orders.where((o) =>
            o.createdAt.year == today.year && o.createdAt.month == today.month && o.createdAt.day == today.day);
        final open = orders.where((o) =>
            o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled);
        final revenue = orders
            .where((o) => o.status != OrderStatus.cancelled)
            .fold<int>(0, (s, o) => s + o.total);
        final stats = [
          ('Orders today', '${todays.length}', Icons.today_outlined),
          ('Open orders', '${open.length}', Icons.pending_actions_outlined),
          ('Revenue (all time)', rupees(revenue), Icons.payments_outlined),
          ('Menu items', '${state.menu.length}', Icons.restaurant_menu_outlined),
        ];
        return ListView(padding: const EdgeInsets.all(24), children: [
          Text('Dashboard', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Wrap(spacing: 16, runSpacing: 16, children: [
            for (final (label, value, icon) in stats)
              SizedBox(
                width: 220,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(icon, color: t.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(value, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      Text(label, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 28),
          Row(children: [
            Text('Open orders', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(onPressed: () => onOpen(2), child: const Text('All orders →')),
          ]),
          const SizedBox(height: 8),
          if (open.isEmpty)
            const Card(child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('No open orders')))
          else
            for (final o in open.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrderCard(order: o, trailing: _StatusMenu(order: o)),
              ),
        ]);
      },
    );
  }
}

// --------------------------------------------------------------------- menu
class _MenuAdmin extends StatefulWidget {
  const _MenuAdmin();
  @override
  State<_MenuAdmin> createState() => _MenuAdminState();
}

class _MenuAdminState extends State<_MenuAdmin> {
  String _query = '';

  Future<void> _edit(MenuItem? item) async {
    final state = context.read<AppState>();
    final result = await showDialog<MenuItem>(context: context, builder: (_) => MenuItemDialog(item: item));
    if (result == null || !mounted) return;
    try {
      await state.backend.saveMenuItem(result);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${result.name} ${item == null ? 'added' : 'saved'}')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _delete(MenuItem item) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text('It disappears from the customer menu. Past orders keep their copy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(96, 44), backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.backend.deleteMenuItem(item.id);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = Theme.of(context);
    final q = _query.toLowerCase();
    final items = state.menu
        .where((m) => q.isEmpty || m.name.toLowerCase().contains(q) || m.category.toLowerCase().contains(q))
        .toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 96), children: [
        Row(children: [
          Expanded(
            child: Text('Menu (${state.menu.length})',
                style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              decoration: const InputDecoration(
                  isDense: true, hintText: 'Filter by name or category', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (state.menu.isEmpty)
          EmptyState(
            icon: Icons.restaurant_menu,
            title: 'No menu items yet',
            message: 'Add dishes one by one, or load the 19-item sample menu.',
            action: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
              onPressed: () => state.backend.seedMenu(),
              icon: const Icon(Icons.download),
              label: const Text('Load sample menu'),
            ),
          )
        else
          Card(
            child: Column(children: [
              for (final m in items) ...[
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 52, height: 52, child: FoodImage(m.image)),
                  ),
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${m.category} · ${rupees(m.price)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Tooltip(
                      message: m.available ? 'Available' : 'Sold out',
                      child: Switch(
                        value: m.available,
                        onChanged: (v) => state.backend.saveMenuItem(m.copyWith(available: v)),
                      ),
                    ),
                    IconButton(tooltip: 'Edit', onPressed: () => _edit(m), icon: const Icon(Icons.edit_outlined)),
                    IconButton(tooltip: 'Delete', onPressed: () => _delete(m), icon: const Icon(Icons.delete_outline)),
                  ]),
                ),
                if (m != items.last) const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ]),
          ),
      ]),
    );
  }
}

/// Add / edit form. Returns the edited item (id '' for new ones).
class MenuItemDialog extends StatefulWidget {
  const MenuItemDialog({super.key, this.item});
  final MenuItem? item;
  @override
  State<MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<MenuItemDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _price = TextEditingController(text: widget.item?.price.toString());
  late final _description = TextEditingController(text: widget.item?.description);
  late final _image = TextEditingController(text: widget.item?.image ?? '');
  late String _category = widget.item?.category ?? MenuItem.categories.first;
  late bool _available = widget.item?.available ?? true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add menu item' : 'Edit ${widget.item!.name}'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: ListenableBuilder(listenable: _image, builder: (_, _) => FoodImage(_image.text)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (Rs)'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        return n == null || n <= 0 ? 'Enter a whole number above 0' : null;
                      },
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: MenuItem.categories.contains(_category) ? _category : MenuItem.categories.first,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [for (final c in MenuItem.categories) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _image,
                decoration: const InputDecoration(
                  labelText: 'Image',
                  helperText: 'https:// URL, or asset:assets/menu/<file>.jpg for a bundled photo',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available'),
                value: _available,
                onChanged: (v) => setState(() => _available = v),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              MenuItem(
                id: widget.item?.id ?? '',
                name: _name.text.trim(),
                price: int.parse(_price.text.trim()),
                category: _category,
                image: _image.text.trim(),
                description: _description.text.trim(),
                available: _available,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- orders
class _OrdersAdmin extends StatefulWidget {
  const _OrdersAdmin();
  @override
  State<_OrdersAdmin> createState() => _OrdersAdminState();
}

class _OrdersAdminState extends State<_OrdersAdmin> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = Theme.of(context);
    return StreamBuilder<List<FoodOrder>>(
      stream: state.backend.watchOrders(),
      builder: (context, snap) {
        final all = snap.data ?? const <FoodOrder>[];
        final orders = all.where((o) => _filter == null || o.status == _filter).toList();
        return ListView(padding: const EdgeInsets.all(24), children: [
          Text('Orders (${all.length})', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in [null, ...OrderStatus.values])
              FilterChip(
                label: Text('${s?.label ?? 'All'} (${all.where((o) => s == null || o.status == s).length})'),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
          ]),
          const SizedBox(height: 16),
          if (snap.hasError)
            EmptyState(icon: Icons.cloud_off, title: "Couldn't load orders", message: '${snap.error}')
          else if (!snap.hasData)
            const Center(child: CircularProgressIndicator())
          else if (orders.isEmpty)
            const EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders', message: 'Nothing matches this filter.')
          else
            for (final o in orders)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrderCard(order: o, trailing: _StatusMenu(order: o)),
              ),
        ]);
      },
    );
  }
}

/// Dropdown to move an order through placed → … → delivered.
class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.order});
  final FoodOrder order;

  @override
  Widget build(BuildContext context) {
    final backend = context.read<AppState>().backend;
    return PopupMenuButton<OrderStatus>(
      tooltip: 'Change status',
      initialValue: order.status,
      onSelected: (s) => backend.updateOrderStatus(order.id, s),
      itemBuilder: (_) => [
        for (final s in OrderStatus.values) PopupMenuItem(value: s, child: StatusChip(s)),
      ],
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.more_vert),
      ),
    );
  }
}
