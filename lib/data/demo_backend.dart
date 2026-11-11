import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'backend.dart';
import 'seed_data.dart';

/// Runs entirely in the browser: data lives in memory and is persisted to
/// local storage (shared_preferences), so a demo survives page reloads.
/// No network, no keys.
class DemoBackend implements Backend {
  DemoBackend._(this._prefs);

  static const _storageKey = 'hungry_haste_demo_v1';

  static Future<DemoBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    final backend = DemoBackend._(prefs);
    backend._load();
    return backend;
  }

  final SharedPreferences _prefs;

  // email -> {uid, passwordHash, user}
  final Map<String, Map<String, dynamic>> _accounts = {};
  final Map<String, MenuItem> _menu = {};
  final Map<String, Map<String, int>> _carts = {};
  final Map<String, FoodOrder> _orders = {};
  String? _sessionEmail;

  final _menuCtrl = StreamController<List<MenuItem>>.broadcast();
  final _ordersCtrl = StreamController<void>.broadcast();

  @override
  String get label => 'Demo mode';
  @override
  bool get isDemo => true;

  // ---------------------------------------------------------------- storage
  static String _hash(String password) =>
      sha256.convert(utf8.encode('hungry-haste:$password')).toString();

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      _seed();
      _persist();
      return;
    }
    final j = jsonDecode(raw) as Map<String, dynamic>;
    (j['accounts'] as Map).forEach(
        (k, v) => _accounts[k as String] = Map<String, dynamic>.from(v as Map));
    for (final m in j['menu'] as List) {
      final map = Map<String, dynamic>.from(m as Map);
      _menu[map['id'] as String] = MenuItem.fromJson(map['id'] as String, map);
    }
    (j['carts'] as Map).forEach((k, v) =>
        _carts[k as String] = Map<String, int>.from((v as Map).map((a, b) => MapEntry('$a', (b as num).toInt()))));
    for (final o in j['orders'] as List) {
      final map = Map<String, dynamic>.from(o as Map);
      _orders[map['id'] as String] = FoodOrder.fromJson(map['id'] as String, map);
    }
    _sessionEmail = j['session'] as String?;
  }

  void _persist() {
    _prefs.setString(
      _storageKey,
      jsonEncode({
        'accounts': _accounts,
        'menu': _menu.values.map((m) => {'id': m.id, ...m.toJson()}).toList(),
        'carts': _carts,
        'orders': _orders.values.map((o) => {'id': o.id, ...o.toJson()}).toList(),
        'session': _sessionEmail,
      }),
    );
  }

  void _seed() {
    for (final m in sampleMenu) {
      _menu[m.id] = m;
    }
    _addAccount(
      const AppUser(
        uid: 'demo-customer',
        email: DemoAccounts.customerEmail,
        firstName: 'Ayesha',
        lastName: 'Khan',
        address: '12 Mall Road, Lahore',
        phone: '+92 300 1234567',
        favouriteIds: ['lamb-biryani', 'mango-lassi'],
      ),
      DemoAccounts.customerPassword,
    );
    _addAccount(
      const AppUser(
        uid: 'demo-admin',
        email: DemoAccounts.adminEmail,
        firstName: 'Restaurant',
        lastName: 'Admin',
        isAdmin: true,
      ),
      DemoAccounts.adminPassword,
    );
    // A few past orders so the history and the admin dashboard aren't empty.
    final now = DateTime.now();
    final samples = [
      ('demo-customer', 'Ayesha Khan', '12 Mall Road, Lahore', ['lamb-biryani', 'mango-lassi'], OrderStatus.delivered, 3),
      ('guest-1', 'Bilal Ahmed', '45 Canal View, Lahore', ['margherita', 'strawberry-lemonade', 'brownies'], OrderStatus.onTheWay, 0),
      ('guest-2', 'Sara Malik', 'Pick-up', ['beef-burger', 'yuca-fries'], OrderStatus.preparing, 0),
      ('demo-customer', 'Ayesha Khan', '12 Mall Road, Lahore', ['chicken-handi'], OrderStatus.placed, 0),
    ];
    var n = 1;
    for (final (uid, name, address, ids, status, daysAgo) in samples) {
      final id = 'HH-${1000 + n}';
      _orders[id] = FoodOrder(
        id: id,
        uid: uid,
        customerName: name,
        address: address,
        phone: '+92 300 00000$n',
        lines: [
          for (final i in ids)
            OrderLine(itemId: i, name: _menu[i]!.name, price: _menu[i]!.price, quantity: 1),
        ],
        deliveryFee: address == 'Pick-up' ? 0 : doorDeliveryFee,
        delivery: address == 'Pick-up' ? DeliveryMethod.pickup : DeliveryMethod.door,
        payment: n.isEven ? PaymentMethod.cash : PaymentMethod.card,
        status: status,
        createdAt: now.subtract(Duration(days: daysAgo, minutes: 25 * n)),
      );
      n++;
    }
  }

  void _addAccount(AppUser user, String password) {
    _accounts[user.email.toLowerCase()] = {
      'uid': user.uid,
      'passwordHash': _hash(password),
      'user': {...user.toJson(), if (user.isAdmin) 'role': 'admin'},
    };
  }

  AppUser _userFor(String email) {
    final acc = _accounts[email]!;
    return AppUser.fromJson(acc['uid'] as String, Map<String, dynamic>.from(acc['user'] as Map));
  }

  String? _emailForUid(String uid) =>
      _accounts.entries.where((e) => e.value['uid'] == uid).firstOrNull?.key;

  Future<void> _latency() => Future.delayed(const Duration(milliseconds: 350));

  // ------------------------------------------------------------------- auth
  @override
  AppUser? get currentUser => _sessionEmail == null ? null : _userFor(_sessionEmail!);

  @override
  Future<AppUser?> restoreSession() async => currentUser;

  @override
  Future<AppUser> signIn(String email, String password) async {
    await _latency();
    final key = email.trim().toLowerCase();
    final acc = _accounts[key];
    if (acc == null || acc['passwordHash'] != _hash(password)) {
      throw BackendException('Wrong email or password.');
    }
    _sessionEmail = key;
    _persist();
    return _userFor(key);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String address,
    String phone = '',
  }) async {
    await _latency();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw BackendException('An account already exists for that email.');
    }
    final user = AppUser(
      uid: 'u-${DateTime.now().microsecondsSinceEpoch}',
      email: key,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      address: address.trim(),
      phone: phone.trim(),
    );
    _addAccount(user, password);
    _sessionEmail = key;
    _persist();
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await _latency();
    // Simulated Google account: no popup in demo mode.
    const key = 'google.user@gmail.com';
    if (!_accounts.containsKey(key)) {
      _addAccount(
        const AppUser(uid: 'demo-google', email: key, firstName: 'Google', lastName: 'User'),
        'not-used-${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    _sessionEmail = key;
    _persist();
    return _userFor(key);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _latency();
    // Nothing is sent in demo mode; the UI says so.
  }

  @override
  Future<void> signOut() async {
    _sessionEmail = null;
    _persist();
  }

  // ---------------------------------------------------------------- profile
  @override
  Future<AppUser> updateProfile(AppUser user, {Uint8List? photo}) async {
    await _latency();
    var updated = user;
    if (photo != null) {
      updated = user.copyWith(imageUrl: 'data:image/jpeg;base64,${base64Encode(photo)}');
    }
    final email = _emailForUid(user.uid)!;
    final role = (_accounts[email]!['user'] as Map)['role'];
    _accounts[email]!['user'] = {...updated.toJson(), 'role': ?role};
    _persist();
    return _userFor(email);
  }

  @override
  Future<void> setFavourites(String uid, List<String> ids) async {
    final email = _emailForUid(uid);
    if (email == null) return;
    (_accounts[email]!['user'] as Map)['favouriteFood'] = ids;
    _persist();
  }

  // ------------------------------------------------------------------- menu
  List<MenuItem> get _menuList =>
      _menu.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  @override
  Stream<List<MenuItem>> watchMenu() async* {
    yield _menuList;
    yield* _menuCtrl.stream;
  }

  @override
  Future<void> saveMenuItem(MenuItem item) async {
    await _latency();
    final id = item.id.isEmpty ? 'item-${DateTime.now().microsecondsSinceEpoch}' : item.id;
    _menu[id] = item.copyWith(id: id);
    _persist();
    _menuCtrl.add(_menuList);
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    await _latency();
    _menu.remove(id);
    _persist();
    _menuCtrl.add(_menuList);
  }

  @override
  Future<void> seedMenu() async {
    for (final m in sampleMenu) {
      _menu[m.id] = m;
    }
    _persist();
    _menuCtrl.add(_menuList);
  }

  // ------------------------------------------------------------------- cart
  @override
  Future<Map<String, int>> loadCart(String uid) async => Map.of(_carts[uid] ?? {});

  @override
  Future<void> saveCart(String uid, Map<String, int> quantities) async {
    _carts[uid] = Map.of(quantities);
    _persist();
  }

  // ----------------------------------------------------------------- orders
  List<FoodOrder> _ordersFor(String? uid) => _orders.values
      .where((o) => uid == null || o.uid == uid)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<FoodOrder> placeOrder(FoodOrder order) async {
    await _latency();
    final id = 'HH-${1000 + _orders.length + 1}';
    final saved = order.copyWith(id: id);
    _orders[id] = saved;
    _carts.remove(order.uid);
    _persist();
    _ordersCtrl.add(null);
    return saved;
  }

  @override
  Stream<List<FoodOrder>> watchOrders({String? uid}) async* {
    yield _ordersFor(uid);
    await for (final _ in _ordersCtrl.stream) {
      yield _ordersFor(uid);
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final o = _orders[orderId];
    if (o == null) return;
    _orders[orderId] = o.copyWith(status: status);
    _persist();
    _ordersCtrl.add(null);
  }

  /// Clears local storage and re-seeds (used by "Reset demo data").
  Future<void> reset() async {
    _accounts.clear();
    _menu.clear();
    _carts.clear();
    _orders.clear();
    _sessionEmail = null;
    _seed();
    _persist();
    _menuCtrl.add(_menuList);
    _ordersCtrl.add(null);
  }
}
