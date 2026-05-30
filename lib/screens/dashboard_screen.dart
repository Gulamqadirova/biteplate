import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(String page) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  String _timeAgo(String ts) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(ts));
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) { return ''; }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final d = state.dashboard;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE', style: GoogleFonts.spaceGrotesk(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.accent, letterSpacing: 1.5)),
              ]),
              const SizedBox(height: 10),
              Text('${_greeting()}, Milana 🕊',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              Text('Here is your restaurant at a glance.',
                  style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3)),
              const SizedBox(height: 22),
              // Workflow steps — each navigates to correct page
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final step in [
                  ['1', 'Seat',    'tables'],
                  ['2', 'Order',   'orders'],
                  ['3', 'Kitchen', 'kitchen'],
                  ['4', 'Serve',   'tables'],
                  ['5', 'Pay',     'billing'],
                  ['6', 'Report',  'history'],
                ])
                  GestureDetector(
                    onTap: () => onNavigate(step[2]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border2)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(5)),
                          child: Center(child: Text(step[0], style: GoogleFonts.spaceGrotesk(
                              fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.accentText))),
                        ),
                        const SizedBox(width: 7),
                        Text(step[1], style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
                      ]),
                    ),
                  ),
              ]),
            ])),
            const SizedBox(width: 28),
            // Mini stats
            Column(children: [
              _miniStat('${d['todayOrderCount'] ?? 0}', "Today's Orders", AppColors.accent,
                      () => onNavigate('history')),
              const SizedBox(height: 10),
              _miniStat('£${(d['todayRevenue'] ?? 0.0).toStringAsFixed(0)}', 'Revenue',
                  AppColors.green, () => onNavigate('billing')),
              const SizedBox(height: 10),
              _miniStat('${d['occupiedTables'] ?? 0}', 'Tables Busy', AppColors.yellow,
                      () => onNavigate('tables')),
            ]),
          ]),
        ),
        const SizedBox(height: 18),

        // Stat cards
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => onNavigate('history'),
            child: StatCard(icon: '📋', value: '${d['todayOrderCount'] ?? 0}',
                label: "Today's Orders", sub: "${d['pendingOrders'] ?? 0} pending",
                iconBg: AppColors.accentDim, accentColor: AppColors.accent),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => onNavigate('tables'),
            child: StatCard(icon: '🪑', value: '${d['occupiedTables'] ?? 0}',
                label: 'Occupied Tables', sub: 'in service now',
                iconBg: AppColors.redDim, accentColor: AppColors.red),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => onNavigate('billing'),
            child: StatCard(icon: '💷', value: '£${(d['todayRevenue'] ?? 0.0).toStringAsFixed(2)}',
                label: "Today's Revenue", sub: "${d['readyOrders'] ?? 0} awaiting payment",
                iconBg: AppColors.greenDim, accentColor: AppColors.green),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => onNavigate('staff'),
            child: StatCard(icon: '👤', value: '${d['activeStaff'] ?? 0}',
                label: 'Active Staff', sub: 'all on shift',
                iconBg: AppColors.purpleDim, accentColor: AppColors.purple),
          )),
        ]),
        const SizedBox(height: 18),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Live status
          Expanded(flex: 4, child: BpCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(children: [
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Live Status', style: GoogleFonts.spaceGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                ]),
              ),
              Container(height: 1, color: AppColors.border),
              ...[
                ['Awaiting',   '${d['pendingOrders'] ?? 0}',      AppColors.text3,  Icons.hourglass_top_rounded,          'orders'],
                ['In Kitchen', '${d['preparingOrders'] ?? 0}',    AppColors.orange, Icons.local_fire_department_rounded,   'kitchen'],
                ['Ready',      '${d['readyOrders'] ?? 0}',        AppColors.green,  Icons.check_circle_outline_rounded,    'kitchen'],
                ['Queued',     '${d['kitchenQueueCount'] ?? 0}',  AppColors.blue,   Icons.queue_rounded,                   'kitchen'],
              ].map((row) => GestureDetector(
                onTap: () => onNavigate(row[4] as String),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                            color: (row[2] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9)),
                        child: Icon(row[3] as IconData, size: 16, color: row[2] as Color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(row[0] as String, style: GoogleFonts.spaceGrotesk(
                          fontSize: 13, color: AppColors.text2))),
                      Text(row[1] as String, style: GoogleFonts.spaceGrotesk(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.text3),
                    ]),
                  ),
                  Container(height: 1, color: AppColors.border),
                ]),
              )),
              const SizedBox(height: 4),
            ]),
          )),
          const SizedBox(width: 12),

          // Recent orders
          Expanded(flex: 6, child: BpCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(children: [
                  Text('Recent Orders', style: GoogleFonts.spaceGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => onNavigate('history'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.accentDim,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
                      child: Text('View all →', style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ),
                  ),
                ]),
              ),
              Container(height: 1, color: AppColors.border),
              if ((d['recentOrders'] as List<dynamic>? ?? []).isEmpty)
                const Padding(padding: EdgeInsets.all(28),
                    child: EmptyState(icon: '🧾', message: 'No orders yet today'))
              else
                ...((d['recentOrders'] as List<dynamic>? ?? []).take(6).map((r) {
                  final code = 'BP-${r['orderId'].toString().padLeft(4, '0')}';
                  return GestureDetector(
                    onTap: () => onNavigate('history'),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.accentDim,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2))),
                            child: Center(child: Text(r['orderId'].toString().padLeft(3, '0'),
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(code, style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                              const SizedBox(width: 8),
                              StatusBadge.forOrderStatus(r['status'] ?? ''),
                            ]),
                            const SizedBox(height: 3),
                            Text("Table ${r['tableNumber']} · ${r['itemCount'] ?? 0} items · ${_timeAgo(r['timestamp'] ?? '')}",
                                style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
                          ])),
                          Text('£${(r['total'] ?? 0.0).toStringAsFixed(2)}',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        ]),
                      ),
                      Container(height: 1, color: AppColors.border),
                    ]),
                  );
                })),
              const SizedBox(height: 4),
            ]),
          )),
        ]),
      ]),
    );
  }

  Widget _miniStat(String value, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
        ]),
      ),
    );
  }
}