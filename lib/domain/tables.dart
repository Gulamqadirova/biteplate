import 'errors.dart';

abstract class TableState {
  const TableState();

  String get tag;

  TableState seat(RestaurantTable table) =>
      _illegal('seat a customer at');
  TableState reserve(RestaurantTable table) => _illegal('reserve');
  TableState requestBill(RestaurantTable table) => _illegal('request the bill for');
  TableState clear(RestaurantTable table) => _illegal('clear');

  TableState _illegal(String action) =>
      throw DomainException('Cannot $action a table that is "$tag".');
}

class FreeState extends TableState {
  const FreeState();
  @override
  String get tag => 'free';
  @override
  TableState seat(RestaurantTable table) => const OccupiedState();
  @override
  TableState reserve(RestaurantTable table) => const ReservedState();
}

class ReservedState extends TableState {
  const ReservedState();
  @override
  String get tag => 'reserved';
  @override
  TableState seat(RestaurantTable table) => const OccupiedState();
  @override
  TableState clear(RestaurantTable table) => const FreeState();
}

class OccupiedState extends TableState {
  const OccupiedState();
  @override
  String get tag => 'occupied';
  @override
  TableState requestBill(RestaurantTable table) => const AwaitingBillState();
  @override
  TableState clear(RestaurantTable table) => const ClearedState();
}

class AwaitingBillState extends TableState {
  const AwaitingBillState();
  @override
  String get tag => 'awaitingBill';
  @override
  TableState clear(RestaurantTable table) => const ClearedState();
}

class ClearedState extends TableState {
  const ClearedState();
  @override
  String get tag => 'cleared';
  @override
  TableState seat(RestaurantTable table) => const OccupiedState();
  @override
  TableState reserve(RestaurantTable table) => const ReservedState();
}

class RestaurantTable {
  final int number;
  final int capacity;
  TableState _state;
  final List<int> _orderIds = [];

  RestaurantTable(this.number, this.capacity, {TableState? initial})
      : _state = initial ?? const FreeState();

  String get status => _state.tag;
  int get orderCount => _orderIds.length;
  List<int> get orderIds => List.unmodifiable(_orderIds);

  void attachOrder(int orderId) => _orderIds.add(orderId);

  void seat() => _state = _state.seat(this);
  void reserve() => _state = _state.reserve(this);
  void requestBill() => _state = _state.requestBill(this);

  void clear() {
    _state = _state.clear(this);
    _orderIds.clear();
  }
}
