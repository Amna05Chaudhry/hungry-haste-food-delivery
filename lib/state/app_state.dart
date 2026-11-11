import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/seed_data.dart';
import '../models/models.dart';

/// Single source of truth for the customer app: signed-in user, live menu,
/// cart and favourites. Screens read it with `context.watch<AppState>()`.
class AppState extends ChangeNotifier {
  AppState(this.backend, {this.firebaseError}) {
    _menuSub = backend.watchMenu().listen((items) {
      menu = items;
      menuLoaded = true;
      notifyListeners();
    }, onError: (Object e) {
      menuError = '$e';
      menuLoaded = true;
      notifyListeners();
    });
  }

  final Backend backend;

  /// Set when Firebase was requested but could not start (we fell back to demo).
  final String? firebaseError;

  late final StreamSubscription<List<MenuItem>> _menuSub;
  List<MenuItem> menu = const [];
  bool menuLoaded = false;
  String? menuError;

  AppUser? user;
  final Map<String, int> _cart = {};

  bool get signedIn => user != null;

  MenuItem? itemById(String id) => menu.where((m) => m.id == id).firstOrNull;

  // ------------------------------------------------------------------ auth
  Future<void> _afterSignIn(AppUser u) async {
    user = u;
    _cart
      ..clear()
      ..addAll(await backend.loadCart(u.uid));
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    final u = await backend.restoreSession();
    if (u != null) await _afterSignIn(u);
    return u != null;
  }

  Future<void> signIn(String email, String password) async =>
      _afterSignIn(await backend.signIn(email, password));

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String address,
    String phone = '',
  }) async =>
      _afterSignIn(await backend.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        address: address,
        phone: phone,
      ));

  Future<void> signInWithGoogle() async => _afterSignIn(await backend.signInWithGoogle());

  Future<void> signOut() async {
    await backend.signOut();
    user = null;
    _cart.clear();
    notifyListeners();
  }

  Future<void> updateProfile(AppUser updated, {Uint8List? photo}) async {
    user = await backend.updateProfile(updated, photo: photo);
    notifyListeners();
  }

  // ------------------------------------------------------------ favourites
  bool isFavourite(String id) => user?.favouriteIds.contains(id) ?? false;

  List<MenuItem> get favourites =>
      menu.where((m) => isFavourite(m.id)).toList();

  Future<void> toggleFavourite(String id) async {
    final u = user;
    if (u == null) return;
    final ids = [...u.favouriteIds];
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    user = u.copyWith(favouriteIds: ids);
    notifyListeners();
    await backend.setFavourites(u.uid, ids);
  }

  // ------------------------------------------------------------------ cart
  /// Cart lines for items that still exist on the menu.
  List<CartLine> get cart => [
        for (final e in _cart.entries)
          if (itemById(e.key) case final item?) CartLine(item: item, quantity: e.value),
      ];

  int get cartCount => cart.fold(0, (s, l) => s + l.quantity);
  int get cartTotal => cart.fold(0, (s, l) => s + l.subtotal);
  int quantityOf(String id) => _cart[id] ?? 0;

  void addToCart(String id, [int qty = 1]) => setQuantity(id, quantityOf(id) + qty);

  void setQuantity(String id, int qty) {
    if (qty <= 0) {
      _cart.remove(id);
    } else {
      _cart[id] = qty.clamp(1, 99);
    }
    notifyListeners();
    if (user != null) backend.saveCart(user!.uid, Map.of(_cart));
  }

  // ---------------------------------------------------------------- orders
  Future<FoodOrder> placeOrder({
    required DeliveryMethod delivery,
    required PaymentMethod payment,
    required String address,
    required String phone,
  }) async {
    final u = user!;
    final lines = cart;
    if (lines.isEmpty) throw BackendException('Your cart is empty.');
    final order = await backend.placeOrder(FoodOrder(
      id: '',
      uid: u.uid,
      customerName: u.displayName,
      address: delivery == DeliveryMethod.pickup ? 'Pick-up' : address,
      phone: phone,
      lines: [
        for (final l in lines)
          OrderLine(itemId: l.item.id, name: l.item.name, price: l.item.price, quantity: l.quantity),
      ],
      deliveryFee: delivery == DeliveryMethod.door ? doorDeliveryFee : 0,
      delivery: delivery,
      payment: payment,
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
    ));
    _cart.clear();
    notifyListeners();
    return order;
  }

  @override
  void dispose() {
    _menuSub.cancel();
    super.dispose();
  }
}
