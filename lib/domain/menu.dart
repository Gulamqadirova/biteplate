import 'errors.dart';
enum MenuCategory { starter, main, dessert, beverage, combo }

extension MenuCategoryTag on MenuCategory {
  String get tag => switch (this) {
        MenuCategory.starter => 'starter',
        MenuCategory.main => 'main',
        MenuCategory.dessert => 'dessert',
        MenuCategory.beverage => 'beverage',
        MenuCategory.combo => 'combo',
      };
}

abstract class MenuComponent {
  String get name;
  MenuCategory get category;
  double get price;
  Set<String> get allergens;
  String describe({int indent = 0});
}

abstract class MenuItem extends MenuComponent {
  final String _name;
  final double _price;
  final Set<String> _allergens;

  MenuItem(this._name, this._price, {Set<String> allergens = const {}})
      : _allergens = Set.unmodifiable(allergens) {
    if (_name.trim().isEmpty) {
      throw DomainException('Menu item name must not be empty.');
    }
    if (_price < 0) {
      throw DomainException('Menu item price must not be negative.');
    }
  }
  @override
  String get name => _name;
  @override
  double get price => _price;
  @override
  Set<String> get allergens => _allergens;
  @override
  String describe({int indent = 0}) =>
      '${'  ' * indent}$name — £${price.toStringAsFixed(2)}';
}

class Starter extends MenuItem {
  Starter(super.name, super.price, {super.allergens});
  @override
  MenuCategory get category => MenuCategory.starter;
}

class MainCourse extends MenuItem {
  MainCourse(super.name, super.price, {super.allergens});
  @override
  MenuCategory get category => MenuCategory.main;
}

class Dessert extends MenuItem {
  Dessert(super.name, super.price, {super.allergens});
  @override
  MenuCategory get category => MenuCategory.dessert;
}

class Beverage extends MenuItem {
  Beverage(super.name, super.price, {super.allergens});
  @override
  MenuCategory get category => MenuCategory.beverage;
}

// ─────────────────────────── Factory Method ────────────────────────────────
abstract class MenuItemFactory {
  MenuItem create(String name, double price, {Set<String> allergens});
}

class StarterFactory extends MenuItemFactory {
  @override
  MenuItem create(String name, double price, {Set<String> allergens = const {}}) =>
      Starter(name, price, allergens: allergens);
}

class MainCourseFactory extends MenuItemFactory {
  @override
  MenuItem create(String name, double price, {Set<String> allergens = const {}}) =>
      MainCourse(name, price, allergens: allergens);
}

class DessertFactory extends MenuItemFactory {
  @override
  MenuItem create(String name, double price, {Set<String> allergens = const {}}) =>
      Dessert(name, price, allergens: allergens);
}

class BeverageFactory extends MenuItemFactory {
  @override
  MenuItem create(String name, double price, {Set<String> allergens = const {}}) =>
      Beverage(name, price, allergens: allergens);
}


class MenuFactoryRegistry {
  final Map<MenuCategory, MenuItemFactory> _factories = {
    MenuCategory.starter: StarterFactory(),
    MenuCategory.main: MainCourseFactory(),
    MenuCategory.dessert: DessertFactory(),
    MenuCategory.beverage: BeverageFactory(),
  };

  MenuItem build(
    MenuCategory category,
    String name,
    double price, {
    Set<String> allergens = const {},
  }) {
    final factory = _factories[category];
    if (factory == null) {
      throw DomainException('No factory registered for ${category.tag}.');
    }
    return factory.create(name, price, allergens: allergens);
  }
}

// ───────────────────────────── Composite ───────────────────────────────────
class ComboMeal extends MenuComponent {
  @override
  final String name;
  final double _bundleDiscount;
  final List<MenuComponent> _children = [];

  ComboMeal(this.name, {double bundleDiscount = 0}) : _bundleDiscount = bundleDiscount {
    if (_bundleDiscount < 0) {
      throw DomainException('Bundle discount must not be negative.');
    }
  }

  void add(MenuComponent component) => _children.add(component);
  List<MenuComponent> get items => List.unmodifiable(_children);
  @override
  MenuCategory get category => MenuCategory.combo;
  @override
  double get price {
    final gross = _children.fold<double>(0, (sum, c) => sum + c.price);
    return (gross - _bundleDiscount).clamp(0, double.infinity);
  }
  @override
  Set<String> get allergens =>
      _children.fold<Set<String>>({}, (set, c) => set..addAll(c.allergens));
  @override
  String describe({int indent = 0}) {
    final header = '${'  ' * indent}$name (combo) — £${price.toStringAsFixed(2)}';
    final body = _children.map((c) => c.describe(indent: indent + 1)).join('\n');
    return '$header\n$body';
  }
}

// ───────────────────────────── Decorator ───────────────────────────────────
abstract class MenuItemDecorator extends MenuComponent {
  final MenuComponent inner;
  MenuItemDecorator(this.inner);

  @override
  String get name => inner.name;
  @override
  MenuCategory get category => inner.category;
  @override
  double get price => inner.price;
  @override
  Set<String> get allergens => inner.allergens;
  @override
  String describe({int indent = 0}) => inner.describe(indent: indent);
}

class ExtraTopping extends MenuItemDecorator {
  final String label;
  final double cost;
  ExtraTopping(super.inner, this.label, this.cost) {
    if (cost < 0) throw DomainException('Topping cost must not be negative.');
  }

  @override
  double get price => inner.price + cost;

  @override
  String describe({int indent = 0}) =>
      '${inner.describe(indent: indent)}\n${'  ' * (indent + 1)}+ $label '
      '(£${cost.toStringAsFixed(2)})';
}

class SpecialPreparation extends MenuItemDecorator {
  final String instruction;
  SpecialPreparation(super.inner, this.instruction);

  @override
  String describe({int indent = 0}) =>
      '${inner.describe(indent: indent)}\n${'  ' * (indent + 1)}» $instruction';
}

class AllergenFlag extends MenuItemDecorator {
  final String allergen;
  AllergenFlag(super.inner, this.allergen);

  @override
  Set<String> get allergens => {...inner.allergens, allergen};
}
