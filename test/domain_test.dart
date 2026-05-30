// Domain unit tests — exercise the patterns and business rules directly,
// without the HTTP layer. Run with `flutter test`.
import 'package:flutter_test/flutter_test.dart';

import 'package:biteplate_app/domain/billing.dart';
import 'package:biteplate_app/domain/errors.dart';
import 'package:biteplate_app/domain/history.dart';
import 'package:biteplate_app/domain/kitchen.dart';
import 'package:biteplate_app/domain/menu.dart';
import 'package:biteplate_app/domain/observers.dart';
import 'package:biteplate_app/domain/orders.dart';
import 'package:biteplate_app/domain/pricing.dart';
import 'package:biteplate_app/domain/staff.dart';
import 'package:biteplate_app/domain/tables.dart';

Order _sampleOrder() => Order(
      id: 1,
      tableNumber: 3,
      staffId: 'WTR01',
      staffName: 'Bob Smith',
      items: [OrderItem(MainCourse('Ribeye Steak', 24.00), 1)],
    );

void main() {
  group('Factory Method + Composite + Decorator', () {
    test('factory builds the correct concrete type', () {
      final item = MenuFactoryRegistry().build(MenuCategory.dessert, 'Tiramisu', 6.95);
      expect(item, isA<Dessert>());
      expect(item.category, MenuCategory.dessert);
    });

    test('combo prices children uniformly with a bundle discount', () {
      final combo = ComboMeal('Lunch Deal', bundleDiscount: 2)
        ..add(Starter('Soup', 5))
        ..add(MainCourse('Pasta', 10));
      expect(combo.price, 13); // 15 - 2
    });

    test('decorators add price and allergens at runtime', () {
      MenuComponent dish = MainCourse('Pizza', 12, allergens: {'gluten'});
      dish = ExtraTopping(dish, 'Extra cheese', 0.8);
      dish = AllergenFlag(dish, 'dairy');
      expect(dish.price, closeTo(12.8, 0.001));
      expect(dish.allergens, containsAll(<String>['gluten', 'dairy']));
    });
  });

  group('State pattern (table lifecycle)', () {
    test('legal transition Free -> Occupied -> Cleared', () {
      final table = RestaurantTable(1, 4);
      expect(table.status, 'free');
      table.seat();
      expect(table.status, 'occupied');
      table.clear();
      expect(table.status, 'cleared');
    });

    test('illegal transition throws', () {
      final table = RestaurantTable(1, 4); // free
      expect(table.requestBill, throwsA(isA<DomainException>()));
    });
  });

  group('Strategy pattern (pricing)', () {
    test('Happy Hour applies 20% off', () {
      final order = _sampleOrder();
      expect(HappyHourPricing().discountFor(order), closeTo(4.8, 0.001));
    });

    test('catalog resolves unknown strategy to Standard', () {
      expect(PricingCatalog().resolve('nonsense'), isA<StandardPricing>());
    });
  });

  group('Facade pattern (billing)', () {
    test('tax is charged on the discounted subtotal', () {
      final bill = BillingFacade().generate(_sampleOrder(), HappyHourPricing());
      expect(bill.subtotal, 24);
      expect(bill.discount, closeTo(4.8, 0.001));
      expect(bill.tax, closeTo(1.92, 0.001)); // (24 - 4.8) * 0.10
    });

    test('split shares re-sum exactly to the total', () {
      final shares = BillingFacade().split(10.00, 3);
      expect(shares.reduce((a, b) => a + b), closeTo(10.00, 0.001));
    });
  });

  group('Command pattern (kitchen queue + undo)', () {
    test('process then undo restores the previous status', () {
      final order = _sampleOrder();
      final queue = KitchenQueue()..enqueue(PrepareOrderCommand(order, OrderSubject()));
      queue.processNext();
      expect(order.status, OrderStatus.preparing);
      queue.undoLast();
      expect(order.status, OrderStatus.confirmed);
      expect(queue.pending.length, 1); // returned to the queue
    });

    test('undo on empty history throws', () {
      expect(KitchenQueue().undoLast, throwsA(isA<DomainException>()));
    });
  });

  group('Observer pattern', () {
    test('an alert event reaches the allergy observer exactly once', () {
      final feed = NotificationFeed();
      final subject = OrderSubject()
        ..subscribe(WaiterNotifier(feed))
        ..subscribe(AllergyAlertObserver(feed));
      subject.notify(OrderEvent('alert', 'contains nuts'));
      expect(feed.latest.length, 1);
      expect(feed.latest.first.type, 'alert');
    });
  });

  group('Singleton + Iterator (history log)', () {
    setUp(OrderHistoryLog.resetForTesting);

    test('only one instance exists', () {
      expect(identical(OrderHistoryLog(), OrderHistoryLog()), isTrue);
    });

    test('iterator traverses appended records and finds the top dish', () {
      final log = OrderHistoryLog();
      for (var i = 0; i < 2; i++) {
        log.append(OrderRecord(
          orderId: i,
          orderCode: 'BP-000$i',
          tableNumber: 1,
          staffId: 'WTR01',
          staffName: 'Bob',
          itemNames: ['Ribeye Steak'],
          total: 24,
          status: 'billed',
          timestamp: DateTime.now(),
        ));
      }
      var count = 0;
      final it = log.iterator;
      while (it.moveNext()) count++;
      expect(count, 2);
      expect(log.mostFrequentItem, 'Ribeye Steak');
    });
  });

  group('Role-based permissions', () {
    test('chef cannot take orders, waiter can', () {
      expect(() => Chef('C1', 'Tony').require(Permission.takeOrder),
          throwsA(isA<DomainException>()));
      expect(() => Waiter('W1', 'Bob').require(Permission.takeOrder), returnsNormally);
    });

    test('manager has every permission', () {
      final mgr = Manager('M1', 'Sarah');
      expect(Permission.values.every(mgr.can), isTrue);
    });
  });
}
