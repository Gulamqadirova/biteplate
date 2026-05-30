import 'billing.dart';
import 'errors.dart';
import 'history.dart';
import 'kitchen.dart';
import 'menu.dart';
import 'observers.dart';
import 'orders.dart';
import 'pricing.dart';
import 'staff.dart';
import 'tables.dart';

class RestaurantService {
  final List<RestaurantTable> _tables = [];
  final List<MenuItem> _menu = [];
  final List<Order> _orders = [];
  final List<Staff> _staff = [];

  final MenuFactoryRegistry _factory = MenuFactoryRegistry();
  final KitchenQueue _kitchen = KitchenQueue();
  final PricingCatalog _pricing = PricingCatalog();
  final BillingFacade _billing = BillingFacade();
  final OrderHistoryLog _history = OrderHistoryLog();

  final OrderSubject _subject = OrderSubject();
  final NotificationFeed _feed = NotificationFeed();

  PricingStrategy _activeStrategy = StandardPricing();
  int _nextOrderId = 1;

  RestaurantService() {
    _seedStaff();
    _seedMenu();
    _seedTables();
    _wireObservers();
  }

  // ──────────────────────────── Seed data ──────────────────────────────────

  void _seedStaff() {
    _staff.addAll([
      Manager('MGR01', 'Sarah Johnson'),
      Waiter('WTR01', 'Bob Smith'),
      Waiter('WTR02', 'Carol Davis'),
      Waiter('WTR03', 'Mike Brown'),
      Chef('CHF01', 'Antonio Russo'),
      Cashier('CSH01', 'Emma Wilson'),
    ]);
  }

  void _seedMenu() {
    void add(MenuCategory c, String name, double price, [Set<String> a = const {}]) {
      _menu.add(_factory.build(c, name, price, allergens: a));
    }

    add(MenuCategory.starter, 'Bruschetta', 6.50, {'gluten'});
    add(MenuCategory.starter, 'Soup of the Day', 5.95);
    add(MenuCategory.starter, 'Calamari', 8.50, {'gluten', 'shellfish'});
    add(MenuCategory.main, 'Ribeye Steak', 24.00);
    add(MenuCategory.main, 'Margherita Pizza', 12.50, {'gluten', 'dairy'});
    add(MenuCategory.main, 'Grilled Salmon', 18.95, {'fish'});
    add(MenuCategory.main, 'Mushroom Risotto', 14.00, {'dairy'});
    add(MenuCategory.dessert, 'Tiramisu', 6.95, {'dairy', 'egg'});
    add(MenuCategory.dessert, 'Cheesecake', 6.50, {'dairy', 'gluten'});
    add(MenuCategory.beverage, 'House Red Wine', 7.50);
    add(MenuCategory.beverage, 'Sparkling Water', 2.95);
    add(MenuCategory.beverage, 'Espresso', 2.50);
  }

  void _seedTables() {
    const capacities = [2, 2, 4, 4, 4, 6, 6, 2, 4, 4, 8, 2];
    for (var i = 0; i < capacities.length; i++) {
      _tables.add(RestaurantTable(i + 1, capacities[i]));
    }
  }

  void _wireObservers() {
    _subject
      ..subscribe(WaiterNotifier(_feed))
      ..subscribe(ManagerDashboard(_feed))
      ..subscribe(KitchenDisplay(_feed))
      ..subscribe(AllergyAlertObserver(_feed));
  }

  // ───────────────────────────── Lookups ───────────────────────────────────

  RestaurantTable _table(int number) => _tables.firstWhere(
        (t) => t.number == number,
        orElse: () => throw DomainException('Table $number does not exist.'),
      );

  Order _order(int id) => _orders.firstWhere(
        (o) => o.id == id,
        orElse: () => throw DomainException('Order $id does not exist.'),
      );

  Staff _staffMember(String id) => _staff.firstWhere(
        (s) => s.id == id,
        orElse: () => throw DomainException('Staff member "$id" does not exist.'),
      );

  OrderRecord? _record(int orderId) {
    for (final r in _history.records) {
      if (r.orderId == orderId) return r;
    }
    return null;
  }

  // ─────────────────────────── Read models ─────────────────────────────────

  List<Map<String, dynamic>> tablesJson() => [
        for (final t in _tables)
          {
            'tableNumber': t.number,
            'capacity': t.capacity,
            'status': t.status,
            'orderCount': t.orderCount,
          }
      ];

  List<Map<String, dynamic>> menuJson() => [
        for (var i = 0; i < _menu.length; i++)
          {
            'menuIndex': i,
            'name': _menu[i].name,
            'category': _menu[i].category.tag,
            'price': _menu[i].price,
            'allergens': _menu[i].allergens.toList(),
          }
      ];

  List<Map<String, dynamic>> ordersJson() => [
        for (final o in _orders)
          {
            'orderId': o.id,
            'orderCode': o.code,
            'tableNumber': o.tableNumber,
            'staffId': o.staffId,
            'staffName': o.staffName,
            'status': o.status.tag,
            'rawTotal': o.rawTotal,
            'itemCount': o.itemCount,
            'timestamp': o.placedAt.toIso8601String(),
          }
      ];

  List<Map<String, dynamic>> staffJson() => [
        for (final s in _staff)
          {
            'staffId': s.id,
            'name': s.name,
            'role': s.role,
            'initials': s.initials,
            'permissions': s.permissions.map((p) => p.label).toList(),
          }
      ];

  List<Map<String, dynamic>> notificationsJson() => [
        for (final e in _feed.latest.take(40))
          {
            'type': e.type,
            'message': e.message,
            'timestamp': e.timestamp.toIso8601String(),
          }
      ];

  Map<String, dynamic> billingStrategiesJson() => {
        'active': _activeStrategy.name,
        'available': [
          for (final s in _pricing.all)
            {
              'name': s.name,
              'description': s.description,
              'discountPercent': s.discountPercent,
            }
        ],
      };

  Map<String, dynamic> kitchenQueueJson() => {
        'pendingCount': _kitchen.pending.length,
        'historyCount': _kitchen.history.length,
        'pending': [
          for (final c in _kitchen.pending)
            {'type': c.type, 'description': c.description}
        ],
        'history': [
          for (final c in _kitchen.history)
            {'type': c.type, 'description': c.description}
        ],
      };

  Map<String, dynamic> historyJson() => {
        'count': _history.count,
        'totalRevenue': _history.totalRevenue,
        'mostFrequentItem': _history.mostFrequentItem ?? '—',
        'records': [
          for (final r in _history.records)
            {
              'orderId': r.orderId,
              'orderCode': r.orderCode,
              'tableNumber': r.tableNumber,
              'staffId': r.staffId,
              'staffName': r.staffName,
              'itemNames': r.itemNames,
              'total': r.total,
              'status': r.status,
              'timestamp': r.timestamp.toIso8601String(),
            }
        ],
      };

  Map<String, dynamic> dashboardJson() {
    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    int countStatus(OrderStatus s) =>
        _orders.where((o) => o.status == s).length;

    final todays =
        _history.records.where((r) => isToday(r.timestamp)).toList();

    return {
      'todayOrderCount': todays.length,
      'todayRevenue': todays
          .where((r) => r.status != 'cancelled')
          .fold<double>(0, (s, r) => s + r.total),
      'occupiedTables': _tables.where((t) => t.status == 'occupied').length,
      'activeStaff': _staff.length,
      'pendingOrders': countStatus(OrderStatus.confirmed),
      'preparingOrders': countStatus(OrderStatus.preparing),
      'readyOrders': countStatus(OrderStatus.ready),
      'kitchenQueueCount': _kitchen.pending.length,
      'recentOrders': [
        for (final o in _orders.reversed.take(6))
          {
            'orderId': o.id,
            'tableNumber': o.tableNumber,
            'status': o.status.tag,
            'itemCount': o.itemCount,
            'total': o.rawTotal,
            'timestamp': o.placedAt.toIso8601String(),
          }
      ],
    };
  }

  // ─────────────────────────── Commands ────────────────────────────────────

  Map<String, dynamic> seatTable(int number) {
    _table(number).seat();
    _subject.notify(OrderEvent('table', 'Table $number seated'));
    return {'success': true};
  }

  Map<String, dynamic> reserveTable(int number) {
    _table(number).reserve();
    _subject.notify(OrderEvent('table', 'Table $number reserved'));
    return {'success': true};
  }

  Map<String, dynamic> clearTable(int number) {
    _table(number).clear();
    _subject.notify(OrderEvent('table', 'Table $number cleared'));
    return {'success': true};
  }

  Map<String, dynamic> placeOrder(Map<String, dynamic> body) {
    final tableNumber = _asInt(body['tableNumber'], 'tableNumber');
    final staffId = _asString(body['staffId'], 'staffId');
    final staff = _staffMember(staffId);
    staff.require(Permission.takeOrder);

    final rawItems = body['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      throw DomainException('An order must contain at least one item.');
    }

    final table = _table(tableNumber);
    if (table.status != 'occupied') {
      throw DomainException('Table $tableNumber must be occupied before ordering.');
    }

    final orderItems = <OrderItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) throw DomainException('Malformed order item.');
      final index = _asInt(raw['menuIndex'], 'menuIndex');
      if (index < 0 || index >= _menu.length) {
        throw DomainException('Menu item $index does not exist.');
      }
      final quantity = raw['quantity'] == null ? 1 : _asInt(raw['quantity'], 'quantity');

      MenuComponent component = _menu[index];
      final toppingName = raw['toppingName'];
      if (toppingName is String && toppingName.trim().isNotEmpty) {
        final cost = (raw['toppingCost'] as num?)?.toDouble() ?? 0;
        component = ExtraTopping(component, toppingName.trim(), cost);
      }
      final instruction = raw['specialInstruction'];
      if (instruction is String && instruction.trim().isNotEmpty) {
        component = SpecialPreparation(component, instruction.trim());
      }
      orderItems.add(OrderItem(component, quantity));
    }

    final order = Order(
      id: _nextOrderId++,
      tableNumber: tableNumber,
      staffId: staff.id,
      staffName: staff.name,
      items: orderItems,
    );
    _orders.add(order);
    table.attachOrder(order.id);

    // SINGLETON — append to the global audit log.
    _history.append(OrderRecord(
      orderId: order.id,
      orderCode: order.code,
      tableNumber: order.tableNumber,
      staffId: order.staffId,
      staffName: order.staffName,
      itemNames: order.items.map((i) => i.name).toList(),
      total: order.rawTotal,
      status: order.status.tag,
      timestamp: order.placedAt,
    ));

    _kitchen.enqueue(PrepareOrderCommand(order, _subject));
    _subject.notify(OrderEvent('order',
        '${order.code} placed at Table $tableNumber by ${staff.name}'));
    if (order.allergens.isNotEmpty) {
      _subject.notify(OrderEvent('alert',
          '⚠ ${order.code} contains ${order.allergens.join(', ')} — '
          'notify kitchen & manager'));
    }

    return {'success': true, 'order': {'orderId': order.id, 'orderCode': order.code}};
  }

  Map<String, dynamic> processKitchen() {
    final command = _kitchen.processNext();
    return {'success': true, 'message': '${command.description} — done'};
  }

  Map<String, dynamic> undoKitchen() {
    final command = _kitchen.undoLast();
    return {'success': true, 'message': 'Undone: ${command.description}'};
  }

  /// FACADE + STRATEGY — one call hides discount, tax, tip and receipt assembly.
  Map<String, dynamic> generateBill(Map<String, dynamic> body) {
    final orderId = _asInt(body['orderId'], 'orderId');
    final tipPercent = (body['tipPercent'] as num?)?.toDouble() ?? 0;
    final strategy = _pricing.resolve(body['strategy'] as String?);

    final order = _order(orderId);
    if (order.status == OrderStatus.cancelled) {
      throw DomainException('Cannot bill a cancelled order.');
    }

    final bill = _billing.generate(order, strategy, tipPercent: tipPercent);

    if (order.status != OrderStatus.billed) {
      order.forceStatus(OrderStatus.billed);
    }
    final record = _record(orderId);
    if (record != null) {
      record.status = 'billed';
      record.total = bill.grandTotal;
    }
    _table(order.tableNumber).requestBill();
    _subject.notify(OrderEvent('billing',
        'Bill for ${order.code} settled — £${bill.grandTotal.toStringAsFixed(2)}'));

    return {
      'success': true,
      'bill': {
        'orderCode': bill.orderCode,
        'tableNumber': bill.tableNumber,
        'lineItems': [
          for (final li in bill.lineItems)
            {'itemName': li.itemName, 'quantity': li.quantity, 'lineTotal': li.lineTotal}
        ],
        'subtotal': bill.subtotal,
        'discount': bill.discount,
        'strategyUsed': bill.strategyUsed,
        'perk': bill.perk,
        'tax': bill.tax,
        'tip': bill.tip,
        'grandTotal': bill.grandTotal,
      }
    };
  }

  Map<String, dynamic> splitBill(Map<String, dynamic> body) {
    final total = (body['grandTotal'] as num?)?.toDouble() ??
        (throw DomainException('grandTotal is required.'));
    final guests = _asInt(body['guests'], 'guests');
    return {'success': true, 'shares': _billing.split(total, guests)};
  }

  Map<String, dynamic> setStrategy(Map<String, dynamic> body) {
    _activeStrategy = _pricing.resolve(_asString(body['strategy'], 'strategy'));
    return {'success': true, 'active': _activeStrategy.name};
  }

  // ───────────────────────── Input validation ──────────────────────────────

  int _asInt(dynamic value, String field) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw DomainException('Field "$field" must be a whole number.');
  }

  String _asString(dynamic value, String field) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw DomainException('Field "$field" is required.');
  }
}
