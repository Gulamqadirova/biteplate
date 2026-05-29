import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/tables_screen.dart';
import 'screens/other_screens.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const BitePlateApp()));
}

class BitePlateApp extends StatelessWidget {
  const BitePlateApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BitePlate',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainShell(),
    );
  }
}

class _NavItem {
  final String id;
  final String icon;
  final String label;
  final String group;
  const _NavItem({required this.id, required this.icon, required this.label, required this.group});
}

const _navItems = [
  _NavItem(id: 'dashboard', icon: '🏠', label: 'Dashboard', group: 'PLATFORM'),
  _NavItem(id: 'orders', icon: '📋', label: 'Orders', group: 'PLATFORM'),
  _NavItem(id: 'kitchen', icon: '🍳', label: 'Kitchen', group: 'PLATFORM'),
  _NavItem(id: 'menu', icon: '📖', label: 'Menu', group: 'PLATFORM'),
  _NavItem(id: 'tables', icon: '🪑', label: 'Tables', group: 'PLATFORM'),
  _NavItem(id: 'billing', icon: '💳', label: 'Billing', group: 'PLATFORM'),
  _NavItem(id: 'history', icon: '📊', label: 'Reports', group: 'MANAGEMENT'),
  _NavItem(id: 'staff', icon: '👥', label: 'Staff', group: 'MANAGEMENT'),
  _NavItem(id: 'notifications', icon: '🔔', label: 'Bildirishnomalar', group: 'MANAGEMENT'),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _page = 'dashboard';
  Timer? _refreshTimer;
  String _clock = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    final state = context.read<AppState>();
    state.loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      state.loadDashboard();
      state.loadTables();
      state.loadOrders();
      state.loadKitchenQueue();
      state.loadNotifications();
    });
  }

  void _updateClock() {
    final now = TimeOfDay.now();
    setState(() => _clock = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}');
    Future.delayed(const Duration(seconds: 30), _updateClock);
  }

  @override
  void dispose() { _refreshTimer?.cancel(); super.dispose(); }

  String get _pageTitle => switch (_page) {
    'dashboard' => 'Dashboard', 'orders' => 'Orderlar', 'kitchen' => 'Kitchen',
    'menu' => 'Menyu', 'tables' => 'Stollar', 'billing' => "Hisob va To'lov",
    'history' => 'Hisobotlar', 'staff' => 'Xodimlar', 'notifications' => 'Bildirishnomalar', _ => '',
  };

  Widget get _currentScreen => switch (_page) {
    'dashboard' => const DashboardScreen(),
    'orders' => const OrdersScreen(),
    'kitchen' => const KitchenScreen(),
    'menu' => const MenuScreen(),
    'tables' => const TablesScreen(),
    'billing' => const BillingScreen(),
    'history' => const HistoryScreen(),
    'staff' => const StaffScreen(),
    'notifications' => const NotificationsScreen(),
    _ => const DashboardScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final queueCount = state.kitchenQueue['pendingCount'] as int? ?? 0;

    return Scaffold(
      body: Row(children: [
        // Sidebar
        Container(
          width: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Logo
            Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('B', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)))),
              const SizedBox(height: 12),
              Text('BitePlate', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Restaurant SRMS', style: GoogleFonts.inter(fontSize: 11, color: AppColors.sidebarText)),
            ])),
            Container(height: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final group in ['PLATFORM', 'MANAGEMENT']) ...[
                Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                  child: Text(group, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Colors.white.withOpacity(0.35)))),
                ..._navItems.where((n) => n.group == group).map((n) {
                  final active = _page == n.id;
                  final badge = n.id == 'kitchen' && queueCount > 0 ? queueCount : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _page = n.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Text(n.icon, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(n.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.sidebarText))),
                          if (badge > 0)
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                              child: Text('$badge', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white))),
                        ]),
                      ),
                    ),
                  );
                }),
              ],
            ]))),
          ]),
        ),

        // Main area
        Expanded(child: Column(children: [
          // Topbar
            Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            ),
          // Content
          Expanded(child: _currentScreen),
        ])),
      ]),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
