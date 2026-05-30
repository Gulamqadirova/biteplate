/// Billing & POS — FACADE pattern over the Strategy pricing engine, tax,
/// tips and split-bill maths.
///
/// Callers invoke a single [BillingFacade.generate] call; the facade hides the
/// orchestration of discount calculation, tax, tipping and receipt assembly.
/// A [Bill] is composed of [BillLineItem]s that cannot exist on their own
/// (composition).
library;

import 'errors.dart';
import 'orders.dart';
import 'pricing.dart';

/// A single receipt line — owned wholly by its [Bill].
class BillLineItem {
  final String itemName;
  final int quantity;
  final double lineTotal;
  const BillLineItem(this.itemName, this.quantity, this.lineTotal);
}

class Bill {
  final String orderCode;
  final int tableNumber;
  final List<BillLineItem> lineItems;
  final double subtotal;
  final double discount;
  final String strategyUsed;
  final String? perk;
  final double tax;
  final double tip;
  final double grandTotal;

  const Bill({
    required this.orderCode,
    required this.tableNumber,
    required this.lineItems,
    required this.subtotal,
    required this.discount,
    required this.strategyUsed,
    required this.perk,
    required this.tax,
    required this.tip,
    required this.grandTotal,
  });
}

class BillingFacade {
  /// UK VAT on hospitality, expressed once so it is never hard-coded at call
  /// sites.
  static const double taxRate = 0.10;

  /// Builds an itemised bill. Tax is charged on the post-discount subtotal;
  /// tip is charged on top of the taxed amount.
  Bill generate(
    Order order,
    PricingStrategy strategy, {
    double tipPercent = 0,
  }) {
    if (tipPercent < 0 || tipPercent > 100) {
      throw DomainException('Tip percent must be between 0 and 100.');
    }

    final lineItems = [
      for (final item in order.items)
        BillLineItem(item.name, item.quantity, item.lineTotal),
    ];

    final subtotal = order.rawTotal;
    final discount = strategy.discountFor(order).clamp(0, subtotal).toDouble();
    final taxable = subtotal - discount;
    final tax = taxable * taxRate;
    final tip = (taxable + tax) * (tipPercent / 100);
    final grandTotal = taxable + tax + tip;

    return Bill(
      orderCode: order.code,
      tableNumber: order.tableNumber,
      lineItems: lineItems,
      subtotal: subtotal,
      discount: discount,
      strategyUsed: strategy.name,
      perk: strategy.perk,
      tax: tax,
      tip: tip,
      grandTotal: grandTotal,
    );
  }

  /// Splits a grand total between guests, rounding to the penny and pushing any
  /// rounding remainder onto the first guest so the shares always re-sum to the
  /// exact total.
  List<double> split(double grandTotal, int guests) {
    if (guests < 1) {
      throw DomainException('Guest count must be at least 1.');
    }
    if (grandTotal < 0) {
      throw DomainException('Cannot split a negative total.');
    }
    final base = (grandTotal / guests * 100).floor() / 100;
    final shares = List<double>.filled(guests, base);
    final remainder =
        ((grandTotal - base * guests) * 100).round() / 100;
    shares[0] = ((shares[0] + remainder) * 100).round() / 100;
    return shares;
  }
}
