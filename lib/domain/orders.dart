import 'errors.dart';
import 'menu.dart';

enum OrderStatus { confirmed, preparing, ready, served, billed, cancelled }

extension OrderStatusTag on OrderStatus {
  String get tag => name;
}

class OrderItem {
  final MenuComponent component;
  final int quantity;

  OrderItem(this.component, this.quantity) {
    if (quantity < 1) {
      throw DomainException('Quantity must be at least 1.');
    }
  }

  double get lineTotal => component.price * quantity;
  String get name => component.name;
  Set<String> get allergens => component.allergens;
}

class Order {
  final int id;
  final int tableNumber;
  final String staffId;
  final String staffName;
  final DateTime placedAt;
  final List<OrderItem> _items;
  OrderStatus _status = OrderStatus.confirmed;

  Order({
    required this.id,
    required this.tableNumber,
    required this.staffId,
    required this.staffName,
    required List<OrderItem> items,
    DateTime? placedAt,
  })  : _items = List.of(items),
        placedAt = placedAt ?? DateTime.now() {
    if (_items.isEmpty) {
      throw DomainException('An order must contain at least one item.');
    }
  }

  List<OrderItem> get items => List.unmodifiable(_items);
  OrderStatus get status => _status;
  String get code => 'BP-${id.toString().padLeft(4, '0')}';

  double get rawTotal => _items.fold(0, (sum, i) => sum + i.lineTotal);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  Set<String> get allergens =>
      _items.fold<Set<String>>({}, (set, i) => set..addAll(i.allergens));


  void transitionTo(OrderStatus next) {
    const order = [
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.served,
      OrderStatus.billed,
    ];
    if (next == OrderStatus.cancelled) {
      if (_status == OrderStatus.billed) {
        throw DomainException('A billed order cannot be cancelled.');
      }
      _status = next;
      return;
    }
    final from = order.indexOf(_status);
    final to = order.indexOf(next);
    if (from == -1 || to <= from) {
      throw DomainException('Illegal order transition: ${_status.tag} → ${next.tag}.');
    }
    _status = next;
  }

  void forceStatus(OrderStatus status) => _status = status;
}
