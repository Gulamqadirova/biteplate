/// Menu domain — demonstrates three GoF patterns working together:
///
///  * **Composite**  — [MenuComponent] lets a single dish ([MenuItem]) and a
///    multi-item deal ([ComboMeal]) be priced and displayed through one
///    uniform interface.
///  * **Factory Method** — [MenuItemFactory] subclasses decide which concrete
///    [MenuItem] (Starter / MainCourse / Dessert / Beverage) to instantiate.
///  * **Decorator** — [MenuItemDecorator] dynamically wraps any component to
///    add extras (toppings, special prep, allergen flags) at runtime without
///    subclassing.
library;

import 'errors.dart';

/// Category tags shared with the UI layer. Kept as a small enum so the rest of
/// the domain never deals with raw strings.
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

/// COMPOSITE — common contract for both individual dishes and combo deals.
///
/// The billing engine, kitchen routing and UI all program against this
/// interface, so they never need to know whether they hold one dish or fifty.
abstract class MenuComponent {
  String get name;
  MenuCategory get category;

  /// Fully-resolved price including any nested components / decorators.
  double get price;

  /// Allergens contributed by this component and everything it contains.
  Set<String> get allergens;

  /// Human-readable, indentable breakdown used on bills and kitchen tickets.
  String describe({int indent = 0});
}

/// ABSTRACTION — base class for every concrete dish. Encapsulates the shared
/// state (`_name`, `_price`, `_allergens`) behind read-only accessors so price
/// and allergen data cannot be mutated from outside.
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

/// FACTORY METHOD — each subclass owns the creation of one product family.
/// New franchise menus (see Task 4 — Scenario C) subclass this rather than
/// editing the core, so object creation stays open for extension.
abstract class MenuItemFactory {
  /// The factory method subclasses override.
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

/// Convenience registry mapping a category tag to its factory. This is the
/// single seam a new location would extend to register location-specific
/// item families.
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

/// COMPOSITE — a set meal / combo deal that aggregates leaf [MenuComponent]s
/// and may apply a bundle discount, while still being treated as a single
/// priceable, routable component.
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

/// DECORATOR — base wrapper. Forwards everything to the wrapped component and
/// lets concrete decorators selectively override price / allergens / text.
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

/// Adds a priced extra (e.g. "Extra cheese +£0.80").
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

/// Adds a free-text kitchen instruction (no price impact).
class SpecialPreparation extends MenuItemDecorator {
  final String instruction;
  SpecialPreparation(super.inner, this.instruction);

  @override
  String describe({int indent = 0}) =>
      '${inner.describe(indent: indent)}\n${'  ' * (indent + 1)}» $instruction';
}

/// Flags an extra allergen the customer must be warned about.
class AllergenFlag extends MenuItemDecorator {
  final String allergen;
  AllergenFlag(super.inner, this.allergen);

  @override
  Set<String> get allergens => {...inner.allergens, allergen};
}
