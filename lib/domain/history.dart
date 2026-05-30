/// Order history & audit log — SINGLETON + ITERATOR.
///
/// [OrderHistoryLog] is a process-wide singleton (one audit log shared by every
/// subsystem). Records are immutable snapshots. Traversal is exposed through
/// the [Iterator] contract via [records] and the filtering helpers, so callers
/// can scan the log without depending on the internal `List` storage — the
/// storage could become a database cursor tomorrow and reporting code would not
/// change (Task 4 — Scenario D).
library;

/// Audit record. Captures everything analytics needs. Identity fields are
/// immutable; only [status] mutates, tracking the order's final disposition
/// (confirmed → billed / cancelled) for the audit trail.
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
  // Eager, lazily-exposed singleton instance.
  static final OrderHistoryLog _instance = OrderHistoryLog._internal();
  factory OrderHistoryLog() => _instance;
  OrderHistoryLog._internal();

  /// Test seam — lets unit tests start from a clean log without reaching into
  /// private state.
  static void resetForTesting() => _instance._records.clear();

  final List<OrderRecord> _records = [];

  void append(OrderRecord record) => _records.add(record);

  int get count => _records.length;

  /// ITERATOR — uniform read-only traversal, independent of storage.
  Iterator<OrderRecord> get iterator => _records.iterator;

  /// All records, newest last. Returned as an iterable view.
  Iterable<OrderRecord> get records => List.unmodifiable(_records);

  // ── Query helpers built purely on the iterator, not on the List type ──

  Iterable<OrderRecord> inRange(DateTime from, DateTime to) =>
      records.where((r) => !r.timestamp.isBefore(from) && !r.timestamp.isAfter(to));

  Iterable<OrderRecord> forTable(int tableNumber) =>
      records.where((r) => r.tableNumber == tableNumber);

  double get totalRevenue =>
      records.where((r) => r.status != 'cancelled').fold(0, (s, r) => s + r.total);

  /// Most frequently ordered single dish across the whole log.
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
