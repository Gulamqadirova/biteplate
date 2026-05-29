import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  List<dynamic> tables = [];
  List<dynamic> menu = [];
  List<dynamic> orders = [];
  List<dynamic> staff = [];
  List<dynamic> notifications = [];
  Map<String, dynamic> dashboard = {};
  Map<String, dynamic> history = {};
  Map<String, dynamic> kitchenQueue = {};
  Map<String, dynamic> billingStrategies = {};
  bool loading = false;
  String? error;

  Future<void> loadAll() async {
    await Future.wait([
      loadTables(), loadMenu(), loadOrders(),
      loadDashboard(), loadHistory(), loadKitchenQueue(),
      loadStaff(), loadNotifications(), loadBillingStrategies(),
    ]);
  }

  Future<void> loadTables() async {
    final d = await ApiService.get('/tables');
    if (d is List) { tables = d; notifyListeners(); }
  }

  Future<void> loadMenu() async {
    final d = await ApiService.get('/menu');
    if (d is List) { menu = d; notifyListeners(); }
  }

  Future<void> loadOrders() async {
    final d = await ApiService.get('/orders');
    if (d is List) { orders = d; notifyListeners(); }
  }

  Future<void> loadDashboard() async {
    final d = await ApiService.get('/dashboard');
    if (d is Map) { dashboard = Map<String, dynamic>.from(d); notifyListeners(); }
  }

  Future<void> loadHistory() async {
    final d = await ApiService.get('/history');
    if (d is Map) { history = Map<String, dynamic>.from(d); notifyListeners(); }
  }

  Future<void> loadKitchenQueue() async {
    final d = await ApiService.get('/kitchen/queue');
    if (d is Map) { kitchenQueue = Map<String, dynamic>.from(d); notifyListeners(); }
  }

  Future<void> loadStaff() async {
    final d = await ApiService.get('/staff');
    if (d is List) { staff = d; notifyListeners(); }
  }

  Future<void> loadNotifications() async {
    final d = await ApiService.get('/notifications');
    if (d is List) { notifications = d; notifyListeners(); }
  }

  Future<void> loadBillingStrategies() async {
    final d = await ApiService.get('/billing/strategies');
    if (d is Map) { billingStrategies = Map<String, dynamic>.from(d); notifyListeners(); }
  }

  Future<Map<String, dynamic>> seatTable(int n) async {
    final r = await ApiService.post('/tables/$n/seat');
    await loadTables(); await loadDashboard();
    return Map<String, dynamic>.from(r);
  }

  Future<Map<String, dynamic>> reserveTable(int n) async {
    final r = await ApiService.post('/tables/$n/reserve');
    await loadTables();
    return Map<String, dynamic>.from(r);
  }

  Future<Map<String, dynamic>> clearTable(int n) async {
    final r = await ApiService.post('/tables/$n/clear');
    await loadTables(); await loadDashboard();
    return Map<String, dynamic>.from(r);
  }

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async {
    final r = await ApiService.post('/orders', body);
    await loadOrders(); await loadKitchenQueue(); await loadDashboard();
    return Map<String, dynamic>.from(r);
  }

  Future<Map<String, dynamic>> processKitchen() async {
    final r = await ApiService.post('/kitchen/process');
    await loadKitchenQueue(); await loadOrders(); await loadNotifications();
    return Map<String, dynamic>.from(r);
  }

  Future<Map<String, dynamic>> undoKitchen() async {
    final r = await ApiService.post('/kitchen/undo');
    await loadKitchenQueue(); await loadOrders();
    return Map<String, dynamic>.from(r);
  }

  Future<Map<String, dynamic>> generateBill(Map<String, dynamic> body) async {
    final r = await ApiService.post('/billing/generate', body);
    await loadHistory(); await loadOrders(); await loadDashboard();
    return Map<String, dynamic>.from(r);
  }

  Future<Map<String, dynamic>> splitBill(double total, int guests) async {
    final r = await ApiService.post('/billing/split', {'grandTotal': total, 'guests': guests});
    return Map<String, dynamic>.from(r);
  }

  Future<void> setStrategy(String name) async {
    await ApiService.post('/billing/strategy', {'strategy': name});
    await loadBillingStrategies();
  }
}
