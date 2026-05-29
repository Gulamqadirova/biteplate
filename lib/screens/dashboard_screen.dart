import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _timeAgo(String ts) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(ts));
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final d = state.dashboard;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)], end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Xayrli kech, Sarah Johnson 👋', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text("Restoran workflow — bosib ishlang", style: GoogleFonts.inter(fontSize: 13, color: Colors.white60)),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final step in [['1','Stol tanlash'],['2','Order olish'],['3','Kitchen'],['4','Xizmat'],["5","To'lov"],['6','Hisobot']])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: Center(child: Text(step[0], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),
                    const SizedBox(width: 7),
                    Text(step[1], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
                  ]),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // Stats grid
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4, crossAxisSpacing: 14, mainAxisSpacing: 14,
          childAspectRatio: 1.5,
          children: [
            StatCard(icon: '📋', value: '${d['todayOrderCount'] ?? 0}', label: 'Bugungi orderlar', sub: "${d['pendingOrders'] ?? 0} pending", iconBg: const Color(0xFFEFF6FF)),
            StatCard(icon: '🔷', value: '${d['occupiedTables'] ?? 0}', label: 'Band stollar', sub: "ta stol band", iconBg: const Color(0xFFFEF2F2)),
            StatCard(icon: '💷', value: '£${(d['todayRevenue'] ?? 0.0).toStringAsFixed(2)}', label: 'Bugungi daromad', sub: "${d['readyOrders'] ?? 0} to'lov kutmoqda", iconBg: const Color(0xFFECFDF5)),
            StatCard(icon: '👤', value: '${d['activeStaff'] ?? 0}', label: 'Faol xodimlar', sub: 'Hammasi faol', iconBg: const Color(0xFFF5F3FF)),
          ],
        ),
        const SizedBox(height: 20),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Live status
          Expanded(
            flex: 4,
            child: BpCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                Padding(padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Jonli holat', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Divider(),
                for (final row in [
                  ['Tasdiqlash kutmoqda', '${d['pendingOrders'] ?? 0}', '9CA3AF'],
                  ['Kitchen da', '${d['preparingOrders'] ?? 0}', 'F97316'],
                  ['Xizmatga tayyor', '${d['readyOrders'] ?? 0}', '10B981'],
                  ["To'lov kutmoqda", '${d['kitchenQueueCount'] ?? 0}', '3B82F6'],
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(
                        color: Color(int.parse('FF${row[2]}', radix: 16)), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(row[0], style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2))),
                      Text(row[1], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.text3),
                    ]),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 14),

          // Recent orders
          Expanded(
            flex: 6,
            child: BpCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Text("So'nggi orderlar", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Barchasi →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue)),
                  ]),
                ),
                const Divider(),
                ...((d['recentOrders'] as List<dynamic>? ?? []).take(6).map((r) {
                  final code = 'BP-${r['orderId'].toString().padLeft(4, '0')}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                        child: Center(child: Text(r['orderId'].toString().padLeft(3, '0'), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(code, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          StatusBadge.forOrderStatus(r['status'] ?? ''),
                        ]),
                        const SizedBox(height: 2),
                        Text("Stol ${r['tableNumber']} · ${r['itemCount'] ?? 0} ta taom · ${_timeAgo(r['timestamp'] ?? '')}", style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('£${(r['total'] ?? 0.0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                  );
                })),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}
