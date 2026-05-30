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
  final IconData icon;
  final String label;
  final String group;
  const _NavItem({required this.id, required this.icon, required this.label, required this.group});
}

const _navItems = [
  _NavItem(id: 'dashboard', icon: Icons.grid_view_rounded, label: 'Dashboard', group: 'OPERATIONS'),
  _NavItem(id: 'orders', icon: Icons.receipt_long_rounded, label: 'Orders', group: 'OPERATIONS'),
  _NavItem(id: 'kitchen', icon: Icons.restaurant_rounded, label: 'Kitchen Queue', group: 'OPERATIONS'),
  _NavItem(id: 'menu', icon: Icons.menu_book_rounded, label: 'Menu', group: 'OPERATIONS'),
  _NavItem(id: 'tables', icon: Icons.table_restaurant_rounded, label: 'Tables', group: 'OPERATIONS'),
  _NavItem(id: 'billing', icon: Icons.point_of_sale_rounded, label: 'Billing & POS', group: 'OPERATIONS'),
  _NavItem(id: 'history', icon: Icons.insights_rounded, label: 'Reports', group: 'MANAGEMENT'),
  _NavItem(id: 'staff', icon: Icons.badge_rounded, label: 'Staff', group: 'MANAGEMENT'),
  _NavItem(id: 'notifications', icon: Icons.notifications_rounded, label: 'Notifications', group: 'MANAGEMENT'),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _page = 'dashboard';
  Timer? _refreshTimer;
  String _clock = '';

  void navigateTo(String page) => setState(() => _page = page);

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
    if (!mounted) return;
    final now = TimeOfDay.now();
    setState(() => _clock =
    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    Future.delayed(const Duration(seconds: 30), _updateClock);
  }
  @override
  void dispose() { _refreshTimer?.cancel(); super.dispose(); }

  String get _pageTitle => _navItems.firstWhere((n) => n.id == _page).label;

  String get _pageSubtitle => switch (_page) {
    'dashboard' => 'Live overview of today\'s service',
    'orders' => 'Take orders and send them to the kitchen',
    'kitchen' => 'Command-based queue with undo support',
    'menu' => 'Dishes, combos and customisation',
    'tables' => 'Floor plan and table lifecycle',
    'billing' => 'Itemised bills, discounts, tips and splits',
    'history' => 'Order history, revenue and analytics',
    'staff' => 'Roles and permissions',
    'notifications' => 'Real-time activity feed',
    _ => '',
  };

  Widget get _currentScreen => switch (_page) {
    'dashboard' => DashboardScreen(onNavigate: navigateTo),
    'orders' => const OrdersScreen(),
    'kitchen' => const KitchenScreen(),
    'menu' => const MenuScreen(),
    'tables' => const TablesScreen(),
    'billing' => const BillingScreen(),
    'history' => const HistoryScreen(),
    'staff' => const StaffScreen(),
    'notifications' => const NotificationsScreen(),
    _ => DashboardScreen(onNavigate: navigateTo),
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final queueCount = state.kitchenQueue['pendingCount'] as int? ?? 0;
    final notifCount = state.notifications.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        // ── Sidebar ──
        Container(
          width: 240,
          color: AppColors.sidebar,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('B', style: GoogleFonts.spaceGrotesk(
                      fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.accentText))),
                ),
                const SizedBox(width: 11),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('BitePlate', style: GoogleFonts.spaceGrotesk(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text('Restaurant SRMS', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.text3)),
                ]),
              ]),
            ),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final group in ['OPERATIONS', 'MANAGEMENT']) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                    child: Text(group, style: GoogleFonts.spaceGrotesk(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, color: AppColors.text3)),
                  ),
                  ..._navItems.where((n) => n.group == group).map((n) {
                    final active = _page == n.id;
                    final badge = n.id == 'kitchen' ? queueCount
                        : (n.id == 'notifications' ? notifCount : 0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _page = n.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accentDim : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: active ? AppColors.accent.withValues(alpha: 0.3) : Colors.transparent),
                          ),
                          child: Row(children: [
                            Icon(n.icon, size: 17,
                                color: active ? AppColors.accent : AppColors.sidebarText),
                            const SizedBox(width: 11),
                            Expanded(child: Text(n.label, style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                color: active ? AppColors.accent : AppColors.sidebarText))),
                            if (badge > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                                child: Text('$badge', style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentText)),
                              ),
                          ]),
                        ),
                      ),
                    );
                  }),
                ],
              ]),
            )),
            Container(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
                  child: Center(child: Text('Mk', style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mikasa', style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                  Text('Manager', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
                ])),
                Icon(Icons.more_vert, size: 15, color: AppColors.text3),
              ]),
            ),
          ]),
        ),

        // ── Main ──
        Expanded(child: Column(children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Column(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_pageTitle, style: GoogleFonts.spaceGrotesk(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                    Text(_pageSubtitle, style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, color: AppColors.text3)),
                  ]),
              const Spacer(),
              _pill(Icons.schedule_rounded, _clock),
              const SizedBox(width: 8),
              _pill(Icons.calendar_today_rounded, _formatDate()),
              const SizedBox(width: 12),
              Stack(clipBehavior: Clip.none, children: [
                GestureDetector(
                  onTap: () => setState(() => _page = 'notifications'),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.border)),
                    child: const Icon(Icons.notifications_none_rounded, size: 17, color: AppColors.text2),
                  ),
                ),
                if (notifCount > 0)
                  Positioned(right: -2, top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        child: Center(child: Text('$notifCount', style: GoogleFonts.spaceGrotesk(
                            fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.accentText))),
                      )),
              ]),
            ]),
          ),
          Expanded(child: Container(color: AppColors.bg, child: _currentScreen)),
        ])),
      ]),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.text3),
      const SizedBox(width: 6),
      Text(text, style: GoogleFonts.spaceGrotesk(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
    ]),
  );

  String _formatDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}