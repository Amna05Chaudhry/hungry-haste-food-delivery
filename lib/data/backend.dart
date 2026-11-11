import 'dart:typed_data';

import '../models/models.dart';

/// Everything the UI needs from a server. Two implementations:
/// [DemoBackend] (in-browser, no setup) and [FirebaseBackend].
abstract class Backend {
  /// Shown in the UI ("Demo mode" badge) and in logs.
  String get label;
  bool get isDemo;

  // ---- Auth ----
  AppUser? get currentUser;
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String address,
    String phone = '',
  });
  Future<AppUser> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  // ---- Profile ----
  Future<AppUser> updateProfile(AppUser user, {Uint8List? photo});
  Future<void> setFavourites(String uid, List<String> ids);

  // ---- Menu ----
  Stream<List<MenuItem>> watchMenu();
  Future<void> saveMenuItem(MenuItem item);
  Future<void> deleteMenuItem(String id);

  /// Writes the bundled sample menu (used on first run of a fresh Firebase
  /// project, from the admin panel).
  Future<void> seedMenu();

  // ---- Cart (kept per user so it survives reloads) ----
  Future<Map<String, int>> loadCart(String uid);
  Future<void> saveCart(String uid, Map<String, int> quantities);

  // ---- Orders ----
  Future<FoodOrder> placeOrder(FoodOrder order);

  /// Orders of one user, or every order when [uid] is null (admin).
  Stream<List<FoodOrder>> watchOrders({String? uid});
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}

/// Error with a message that is safe to show to the user.
class BackendException implements Exception {
  BackendException(this.message);
  final String message;
  @override
  String toString() => message;
}
