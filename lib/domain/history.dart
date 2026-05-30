class OrderRecord {
  final int orderId;
  final String orderCode;
  final int tableNumber;
  final String staffId;
  final String staffName;
  final List<String> itemNames;
  double total;
  String status;
  final DateTime timestamp;

  OrderRecord({
    required this.orderId,
    required this.orderCode,
    required this.tableNumber,
    required this.staffId,
    required this.staffName,
    required this.itemNames,
    required this.total,
    required this.status,
    required this.timestamp,
  });
}

class OrderHistoryLog {
  static final OrderHistoryLog _instance = OrderHistoryLog._internal();
  factory OrderHistoryLog() => _instance;
  OrderHistoryLog._internal();

  static void resetForTesting() => _instance._records.clear();

  final List<OrderRecord> _records = [];

  void append(OrderRecord record) => _records.add(record);

  int get count => _records.length;

  Iterator<OrderRecord> get iterator => _records.iterator;
  Iterable<OrderRecord> get records => List.unmodifiable(_records);

  Iterable<OrderRecord> inRange(DateTime from, DateTime to) =>
      records.where((r) => !r.timestamp.isBefore(from) && !r.timestamp.isAfter(to));

  Iterable<OrderRecord> forTable(int tableNumber) =>
      records.where((r) => r.tableNumber == tableNumber);

  double get totalRevenue =>
      records.where((r) => r.status != 'cancelled').fold(0, (s, r) => s + r.total);

  String? get mostFrequentItem {
    final counts = <String, int>{};
    for (final record in records) {
      for (final item in record.itemNames) {
        counts[item] = (counts[item] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
