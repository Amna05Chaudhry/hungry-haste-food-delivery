import '../models/models.dart';

/// Demo accounts. They only exist in demo mode (in the browser), never in
/// Firebase. Shown on the login screens so a recruiter can click through.
class DemoAccounts {
  static const customerEmail = 'demo@hungryhaste.app';
  static const customerPassword = 'demo1234';
  static const adminEmail = 'admin@hungryhaste.app';
  static const adminPassword = 'admin1234';
}

/// Photos from TheMealDB / TheCocktailDB (free for non-commercial use),
/// bundled in assets/menu so the demo works offline.
const sampleMenu = <MenuItem>[
  MenuItem(
    id: 'lamb-biryani',
    name: 'Lamb Biryani',
    price: 850,
    category: 'Mains',
    image: 'asset:assets/menu/lamb_biryani.jpg',
    description:
        'Fragrant basmati rice layered with slow-cooked lamb, saffron and fried onions. Served with raita.',
  ),
  MenuItem(
    id: 'chicken-handi',
    name: 'Chicken Handi',
    price: 950,
    category: 'Mains',
    image: 'asset:assets/menu/chicken_handi.jpg',
    description: 'Creamy, mildly spiced chicken curry cooked in a clay pot. Best with naan.',
  ),
  MenuItem(
    id: 'chicken-karaage',
    name: 'Chicken Karaage',
    price: 700,
    category: 'Mains',
    image: 'asset:assets/menu/chicken_karaage.jpg',
    description: 'Japanese-style fried chicken marinated in soy, ginger and garlic.',
  ),
  MenuItem(
    id: 'chicken-wings',
    name: 'Crispy Chicken Wings',
    price: 650,
    category: 'Fast food',
    image: 'asset:assets/menu/chicken_wings.jpg',
    description: 'Eight extra-crispy wings with a smoky chilli dip.',
  ),
  MenuItem(
    id: 'beef-burger',
    name: 'Classic Beef Burger',
    price: 750,
    category: 'Fast food',
    image: 'asset:assets/menu/beef_burger.jpg',
    description: 'Grilled beef patty, cheddar, lettuce, tomato and house sauce in a brioche bun.',
  ),
  MenuItem(
    id: 'lamb-burger',
    name: 'Lamb Tzatziki Burger',
    price: 820,
    category: 'Fast food',
    image: 'asset:assets/menu/lamb_burger.jpg',
    description: 'Spiced lamb patty with cool cucumber tzatziki and red onion.',
  ),
  MenuItem(
    id: 'margherita',
    name: 'Margherita Pizza',
    price: 1200,
    category: 'Fast food',
    image: 'asset:assets/menu/margherita.jpg',
    description: 'Stone-baked 10" pizza with tomato, mozzarella and fresh basil.',
  ),
  MenuItem(
    id: 'yuca-fries',
    name: 'Baked Yuca Fries',
    price: 380,
    category: 'Fast food',
    image: 'asset:assets/menu/yuca_fries.jpg',
    description: 'Oven-baked cassava fries with garlic mayo.',
  ),
  MenuItem(
    id: 'lasagne',
    name: 'Beef Lasagne',
    price: 1100,
    category: 'Pasta',
    image: 'asset:assets/menu/lasagne.jpg',
    description: 'Layers of pasta, slow-cooked beef ragù and béchamel, baked until golden.',
  ),
  MenuItem(
    id: 'pasta-salad',
    name: 'Mediterranean Pasta Salad',
    price: 650,
    category: 'Pasta',
    image: 'asset:assets/menu/pasta_salad.jpg',
    description: 'Fusilli with tuna, olives, tomatoes and basil in a lemon dressing.',
  ),
  MenuItem(
    id: 'thai-noodle-soup',
    name: 'Thai Curry Noodle Soup',
    price: 700,
    category: 'Pasta',
    image: 'asset:assets/menu/thai_noodle_soup.jpg',
    description: 'Rice noodles in a coconut red-curry broth with prawns and herbs.',
  ),
  MenuItem(
    id: 'pancakes',
    name: 'Pancake Stack',
    price: 450,
    category: 'Desserts',
    image: 'asset:assets/menu/pancakes.jpg',
    description: 'Fluffy pancakes with berries, butter and maple syrup.',
  ),
  MenuItem(
    id: 'brownies',
    name: 'Raspberry Brownies',
    price: 400,
    category: 'Desserts',
    image: 'asset:assets/menu/brownies.jpg',
    description: 'Fudgy dark-chocolate brownies with fresh raspberries.',
  ),
  MenuItem(
    id: 'carrot-cake',
    name: 'Carrot Cake',
    price: 450,
    category: 'Desserts',
    image: 'asset:assets/menu/carrot_cake.jpg',
    description: 'Spiced carrot cake with cream-cheese frosting and walnuts.',
  ),
  MenuItem(
    id: 'mango-lassi',
    name: 'Mango Lassi',
    price: 300,
    category: 'Drinks',
    image: 'asset:assets/menu/mango_lassi.jpg',
    description: 'Chilled yoghurt drink blended with ripe mango.',
  ),
  MenuItem(
    id: 'masala-chai',
    name: 'Masala Chai',
    price: 180,
    category: 'Drinks',
    image: 'asset:assets/menu/masala_chai.jpg',
    description: 'Black tea brewed with milk, cardamom, ginger and cinnamon.',
  ),
  MenuItem(
    id: 'strawberry-lemonade',
    name: 'Strawberry Lemonade',
    price: 280,
    category: 'Drinks',
    image: 'asset:assets/menu/strawberry_lemonade.jpg',
    description: 'Fresh lemonade with crushed strawberries and mint.',
  ),
  MenuItem(
    id: 'iced-coffee',
    name: 'Iced Coffee',
    price: 350,
    category: 'Drinks',
    image: 'asset:assets/menu/iced_coffee.jpg',
    description: 'Cold espresso over ice with milk.',
  ),
  MenuItem(
    id: 'banana-shake',
    name: 'Banana Milkshake',
    price: 320,
    category: 'Drinks',
    image: 'asset:assets/menu/banana_shake.jpg',
    description: 'Thick milkshake with banana and vanilla ice cream.',
  ),
];

/// Flat delivery fee in rupees (pick-up is free).
const doorDeliveryFee = 150;
