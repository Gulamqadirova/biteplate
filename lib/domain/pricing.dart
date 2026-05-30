/// Pricing & discount engine — STRATEGY pattern.
///
/// Every algorithm implements [PricingStrategy.discountFor]. The billing
/// engine holds a reference to the interface and can swap the concrete
/// strategy at runtime (Happy Hour, Loyalty, Group, Corporate) without any
/// change to [Bill] or the POS — closing the system for modification while
/// keeping it open for new pricing rules.
library;

import 'orders.dart';

abstract class PricingStrategy {
  String get name;
  String get description;

  /// Discount headline shown in the UI (0 means "no discount").
  int get discountPercent;

  /// Money taken off the order subtotal. Returns the discount amount, never a
  /// negative total.
  double discountFor(Order order);

  /// Optional perk surfaced on the receipt (e.g. a free drink).
  String? get perk => null;
}

class StandardPricing implements PricingStrategy {
  @override
  String get name => 'Standard';
  @override
  String get description => 'Regular menu pricing';
  @override
  int get discountPercent => 0;
  @override
  double discountFor(Order order) => 0;
  @override
  String? get perk => null;
}

class HappyHourPricing implements PricingStrategy {
  @override
  String get name => 'Happy Hour';
  @override
  String get description => '20% off the whole order';
  @override
  int get discountPercent => 20;
  @override
  double discountFor(Order order) => order.rawTotal * 0.20;
  @override
  String? get perk => null;
}

class LoyaltyCardPricing implements PricingStrategy {
  @override
  String get name => 'Loyalty Card';
  @override
  String get description => '10% off + a free drink';
  @override
  int get discountPercent => 10;
  @override
  double discountFor(Order order) => order.rawTotal * 0.10;
  @override
  String? get perk => 'Complimentary house drink';
}

class GroupDiscountPricing implements PricingStrategy {
  @override
  String get name => 'Group';
  @override
  String get description => '15% off for parties of 6+';
  @override
  int get discountPercent => 15;
  @override
  double discountFor(Order order) => order.rawTotal * 0.15;
  @override
  String? get perk => null;
}

/// Registry the POS uses to list and resolve strategies by name.
class PricingCatalog {
  final Map<String, PricingStrategy> _strategies = {
    for (final s in [
      StandardPricing(),
      HappyHourPricing(),
      LoyaltyCardPricing(),
      GroupDiscountPricing(),
    ])
      s.name: s,
  };

  List<PricingStrategy> get all => _strategies.values.toList();

  /// Resolves a strategy by name, falling back to Standard for unknown input
  /// (defensive: never let an unexpected value break billing).
  PricingStrategy resolve(String? name) =>
      _strategies[name] ?? _strategies['Standard']!;
}
