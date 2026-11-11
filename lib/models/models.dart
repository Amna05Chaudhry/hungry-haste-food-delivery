/// Plain data classes shared by the demo and Firebase backends.
library;

int _asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.image,
    this.description = '',
    this.available = true,
  });

  final String id;
  final String name;

  /// Price in Pakistani rupees.
  final int price;
  final String category;

  /// Either `asset:assets/menu/x.jpg` for bundled photos or an http(s) URL.
  final String image;
  final String description;
  final bool available;

  static const categories = ['Mains', 'Fast food', 'Pasta', 'Desserts', 'Drinks'];

  MenuItem copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    String? image,
    String? description,
    bool? available,
  }) =>
      MenuItem(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        category: category ?? this.category,
        image: image ?? this.image,
        description: description ?? this.description,
        available: available ?? this.available,
      );

  /// Field names `name`, `image` and `price` match the original Firestore
  /// `food` collection, so an existing database still loads.
  factory MenuItem.fromJson(String id, Map<String, dynamic> json) => MenuItem(
        id: id,
        name: json['name'] as String? ?? 'Unnamed',
        price: _asInt(json['price']),
        category: json['category'] as String? ?? 'Mains',
        image: json['image'] as String? ?? '',
        description: json['description'] as String? ?? '',
        available: json['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'category': category,
        'image': image,
        'description': description,
        'available': available,
      };
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.address = '',
    this.phone = '',
    this.imageUrl,
    this.favouriteIds = const [],
    this.isAdmin = false,
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String address;
  final String phone;

  /// http(s) URL or a `data:image/...;base64,` URI (demo mode).
  final String? imageUrl;
  final List<String> favouriteIds;
  final bool isAdmin;

  String get displayName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? email.split('@').first : n;
  }

  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? address,
    String? phone,
    String? imageUrl,
    List<String>? favouriteIds,
    bool? isAdmin,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        imageUrl: imageUrl ?? this.imageUrl,
        favouriteIds: favouriteIds ?? this.favouriteIds,
        isAdmin: isAdmin ?? this.isAdmin,
      );

  factory AppUser.fromJson(String uid, Map<String, dynamic> json) => AppUser(
        uid: uid,
        email: json['email'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        favouriteIds:
            ((json['favouriteFood'] as List?) ?? const []).map((e) => '$e').toList(),
        isAdmin: json['role'] == 'admin',
      );

  /// `role` is deliberately not written here: only an admin (or the console)
  /// may grant it, see firestore.rules.
  Map<String, dynamic> toJson() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'phone': phone,
        'imageUrl': imageUrl,
        'favouriteFood': favouriteIds,
      };
}

class CartLine {
  const CartLine({required this.item, required this.quantity});
  final MenuItem item;
  final int quantity;
  int get subtotal => item.price * quantity;
  CartLine withQuantity(int q) => CartLine(item: item, quantity: q);
}

enum DeliveryMethod { door, pickup }

enum PaymentMethod { card, bank, cash }

enum OrderStatus { placed, preparing, onTheWay, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.placed => 'Placed',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.onTheWay => 'On the way',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
}

class OrderLine {
  const OrderLine({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
  });
  final String itemId;
  final String name;
  final int price;
  final int quantity;

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        itemId: j['itemId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        price: _asInt(j['price']),
        quantity: _asInt(j['quantity']),
      );

  Map<String, dynamic> toJson() =>
      {'itemId': itemId, 'name': name, 'price': price, 'quantity': quantity};
}

class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.uid,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.lines,
    required this.deliveryFee,
    required this.delivery,
    required this.payment,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String customerName;
  final String address;
  final String phone;
  final List<OrderLine> lines;
  final int deliveryFee;
  final DeliveryMethod delivery;
  final PaymentMethod payment;
  final OrderStatus status;
  final DateTime createdAt;

  int get itemsTotal => lines.fold(0, (s, l) => s + l.price * l.quantity);
  int get total => itemsTotal + deliveryFee;
  int get itemCount => lines.fold(0, (s, l) => s + l.quantity);

  FoodOrder copyWith({String? id, OrderStatus? status}) => FoodOrder(
        id: id ?? this.id,
        uid: uid,
        customerName: customerName,
        address: address,
        phone: phone,
        lines: lines,
        deliveryFee: deliveryFee,
        delivery: delivery,
        payment: payment,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  factory FoodOrder.fromJson(String id, Map<String, dynamic> j) => FoodOrder(
        id: id,
        uid: j['uid'] as String? ?? '',
        customerName: j['customerName'] as String? ?? '',
        address: j['address'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        lines: ((j['lines'] as List?) ?? const [])
            .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        deliveryFee: _asInt(j['deliveryFee']),
        delivery: _enum(DeliveryMethod.values, j['delivery'], DeliveryMethod.door),
        payment: _enum(PaymentMethod.values, j['payment'], PaymentMethod.cash),
        status: _enum(OrderStatus.values, j['status'], OrderStatus.placed),
        createdAt: DateTime.fromMillisecondsSinceEpoch(_asInt(j['createdAt'])),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'customerName': customerName,
        'address': address,
        'phone': phone,
        'lines': lines.map((l) => l.toJson()).toList(),
        'deliveryFee': deliveryFee,
        'total': total,
        'delivery': delivery.name,
        'payment': payment.name,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
