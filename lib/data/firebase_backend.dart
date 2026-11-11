
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'backend.dart';
import 'seed_data.dart';

/// Firestore layout
///   food/{itemId}                 menu items (same collection as the original app)
///   users/{uid}                   profile + favouriteFood[] + optional role:'admin'
///   users/{uid}/cart/{itemId}     {quantity}
///   orders/{orderId}              see FoodOrder.toJson
class FirebaseBackend implements Backend {
  FirebaseBackend();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  AppUser? _user;

  CollectionReference<Map<String, dynamic>> get _food => _db.collection('food');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  @override
  String get label => 'Firebase';
  @override
  bool get isDemo => false;

  @override
  AppUser? get currentUser => _user;

  Future<AppUser> _loadProfile(User fbUser, {Map<String, dynamic>? createWith}) async {
    final ref = _users.doc(fbUser.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final fresh = createWith ??
          AppUser(
            uid: fbUser.uid,
            email: fbUser.email ?? '',
            firstName: (fbUser.displayName ?? '').split(' ').first,
            lastName: (fbUser.displayName ?? '').split(' ').skip(1).join(' '),
            imageUrl: fbUser.photoURL,
          ).toJson();
      await ref.set(fresh);
      return _user = AppUser.fromJson(fbUser.uid, fresh);
    }
    return _user = AppUser.fromJson(fbUser.uid, snap.data()!);
  }

  BackendException _friendly(FirebaseAuthException e) => BackendException(switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Wrong email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Please choose a stronger password (6+ characters).',
        'invalid-email' => 'That email address looks invalid.',
        'popup-closed-by-user' => 'Google sign-in was cancelled.',
        'too-many-requests' => 'Too many attempts. Try again in a minute.',
        _ => e.message ?? 'Sign-in failed (${e.code}).',
      });

  @override
  Future<AppUser?> restoreSession() async {
    final u = _auth.currentUser ?? await _auth.authStateChanges().first;
    return u == null ? null : _loadProfile(u);
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return await _loadProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
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
    try {
      final cred =
          await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = AppUser(
        uid: cred.user!.uid,
        email: email.trim().toLowerCase(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        address: address.trim(),
        phone: phone.trim(),
      );
      await cred.user!.updateDisplayName(user.displayName);
      // Verification mail is sent but not required to log in, so testers
      // aren't blocked; enforce it in rules if you need to.
      await cred.user!.sendEmailVerification();
      return await _loadProfile(cred.user!, createWith: user.toJson());
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      return await _loadProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> signOut() async {
    _user = null;
    await _auth.signOut();
  }

  @override
  Future<AppUser> updateProfile(AppUser user, {Uint8List? photo}) async {
    var updated = user;
    if (photo != null) {
      final ref = FirebaseStorage.instance.ref('users/${user.uid}/avatar.jpg');
      await ref.putData(photo, SettableMetadata(contentType: 'image/jpeg'));
      updated = user.copyWith(imageUrl: await ref.getDownloadURL());
    }
    await _users.doc(user.uid).set(updated.toJson(), SetOptions(merge: true));
    return _user = updated;
  }

  @override
  Future<void> setFavourites(String uid, List<String> ids) =>
      _users.doc(uid).update({'favouriteFood': ids});

  @override
  Stream<List<MenuItem>> watchMenu() => _food.snapshots().map((s) =>
      s.docs.map((d) => MenuItem.fromJson(d.id, d.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<void> saveMenuItem(MenuItem item) async {
    final ref = item.id.isEmpty ? _food.doc() : _food.doc(item.id);
    await ref.set(item.toJson());
  }

  @override
  Future<void> deleteMenuItem(String id) => _food.doc(id).delete();

  @override
  Future<void> seedMenu() async {
    final batch = _db.batch();
    for (final m in sampleMenu) {
      batch.set(_food.doc(m.id), m.toJson());
    }
    await batch.commit();
  }

  @override
  Future<Map<String, int>> loadCart(String uid) async {
    final snap = await _users.doc(uid).collection('cart').get();
    return {for (final d in snap.docs) d.id: (d.data()['quantity'] as num? ?? 1).toInt()};
  }

  @override
  Future<void> saveCart(String uid, Map<String, int> quantities) async {
    final col = _users.doc(uid).collection('cart');
    final existing = await col.get();
    final batch = _db.batch();
    for (final d in existing.docs) {
      if (!quantities.containsKey(d.id)) batch.delete(d.reference);
    }
    quantities.forEach((id, q) => batch.set(col.doc(id), {'foodId': id, 'quantity': q}));
    await batch.commit();
  }

  @override
  Future<FoodOrder> placeOrder(FoodOrder order) async {
    final ref = _orders.doc();
    await ref.set(order.toJson());
    await saveCart(order.uid, {});
    return order.copyWith(id: ref.id);
  }

  @override
  Stream<List<FoodOrder>> watchOrders({String? uid}) {
    Query<Map<String, dynamic>> q = _orders;
    if (uid != null) q = q.where('uid', isEqualTo: uid);
    return q.snapshots().map((s) =>
        s.docs.map((d) => FoodOrder.fromJson(d.id, d.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _orders.doc(orderId).update({'status': status.name});
}
