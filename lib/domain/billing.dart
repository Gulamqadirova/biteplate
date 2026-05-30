import 'errors.dart';
import 'orders.dart';
import 'pricing.dart';

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
  static const double taxRate = 0.10;
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
