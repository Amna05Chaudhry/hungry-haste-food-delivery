import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_delivery_app/app.dart';
import 'package:food_delivery_app/data/demo_backend.dart';
import 'package:food_delivery_app/data/seed_data.dart';
import 'package:food_delivery_app/models/models.dart';
import 'package:food_delivery_app/state/app_state.dart';
import 'package:food_delivery_app/theme.dart';

Future<AppState> freshState() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(await DemoBackend.create());
  await Future<void>.delayed(Duration.zero); // first menu event
  return state;
}

void main() {
  test('rupees() formats thousands', () {
    expect(rupees(850), 'Rs 850');
    expect(rupees(12500), 'Rs 12,500');
  });

  test('demo backend: login, cart, order, admin status update', () async {
    final state = await freshState();
    expect(state.menu.length, sampleMenu.length);

    await expectLater(state.signIn(DemoAccounts.customerEmail, 'wrong'), throwsA(anything));
    await state.signIn(DemoAccounts.customerEmail, DemoAccounts.customerPassword);
    expect(state.user!.firstName, 'Ayesha');

    state.addToCart('lamb-biryani');
    state.addToCart('lamb-biryani');
    state.addToCart('mango-lassi');
    expect(state.cartCount, 3);
    expect(state.cartTotal, 850 * 2 + 300);

    final order = await state.placeOrder(
      delivery: DeliveryMethod.door,
      payment: PaymentMethod.cash,
      address: 'Somewhere',
      phone: '123',
    );
    expect(order.total, 850 * 2 + 300 + doorDeliveryFee);
    expect(state.cartCount, 0);

    await state.backend.updateOrderStatus(order.id, OrderStatus.delivered);
    final mine = await state.backend.watchOrders(uid: state.user!.uid).first;
    expect(mine.firstWhere((o) => o.id == order.id).status, OrderStatus.delivered);
  });

  test('favourites toggle and persist across a reload', () async {
    final state = await freshState();
    await state.signIn(DemoAccounts.customerEmail, DemoAccounts.customerPassword);
    final before = state.isFavourite('margherita');
    await state.toggleFavourite('margherita');
    expect(state.isFavourite('margherita'), !before);

    final reloaded = AppState(await DemoBackend.create()); // same mock prefs
    await reloaded.restoreSession();
    expect(reloaded.isFavourite('margherita'), !before);
  });

  test('admin CRUD on the menu', () async {
    final state = await freshState();
    final backend = state.backend;
    await backend.saveMenuItem(const MenuItem(
        id: '', name: 'Test Samosa', price: 120, category: 'Mains', image: ''));
    await Future<void>.delayed(Duration.zero);
    final added = state.menu.firstWhere((m) => m.name == 'Test Samosa');
    await backend.deleteMenuItem(added.id);
    await Future<void>.delayed(Duration.zero);
    expect(state.menu.any((m) => m.name == 'Test Samosa'), isFalse);
  });

  testWidgets('customer flow: splash -> demo login -> menu', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = await tester.runAsync(freshState);
    await tester.pumpWidget(HungryHasteApp(state: state!));
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Try the demo account'), findsOneWidget);

    await tester.tap(find.text('Try the demo account'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await tester.pumpAndSettle();
    expect(find.text('Delicious food for you'), findsOneWidget);
    expect(find.text('Lamb Biryani'), findsWidgets);

    // Search filters the grid.
    await tester.enterText(find.byType(SearchBar), 'lassi');
    await tester.pumpAndSettle();
    expect(find.text('Mango Lassi'), findsOneWidget);
    expect(find.text('Lamb Biryani'), findsNothing);
  });
}
