import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});
  @override State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  int? _acting;

  Color _topColor(String status) => switch (status) {
    'free' => AppColors.green,
    'occupied' => AppColors.red,
    'reserved' => AppColors.orange,
    'awaitingBill' => AppColors.blue,
    _ => AppColors.border2,
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Floor Plan', subtitle: 'State pattern — Free → Reserved → Occupied → Awaiting Bill → Cleared'),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
          itemCount: state.tables.length,
          itemBuilder: (ctx, i) {
            final t = state.tables[i];
            final status = t['status'] ?? 'free';
            final num = t['tableNumber'] as int;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Column(children: [
                Container(height: 3, decoration: BoxDecoration(
                  color: _topColor(status), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
                Expanded(child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('T$num', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (_acting == num) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ]),
                    Text('${t['capacity']} seats', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                    const SizedBox(height: 8),
                    StatusBadge.forTableStatus(status),
                    const SizedBox(height: 4),
                    Text('${t['orderCount']} orders', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                    const Spacer(),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (status == 'free' || status == 'cleared')
                        _ActionBtn('Seat', AppColors.green, () => _seat(num)),
                      if (status == 'free')
                        _ActionBtn('Reserve', AppColors.orange, () => _reserve(num)),
                      if (status == 'reserved')
                        _ActionBtn('Seat', AppColors.green, () => _seat(num)),
                      if (status == 'occupied')
                        _ActionBtn('Clear', AppColors.red, () => _clear(num)),
                      if (status == 'awaitingBill')
                        _ActionBtn('Clear', AppColors.blue, () => _clear(num)),
                    ]),
                  ]),
                )),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _ActionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }

  Future<void> _seat(int n) async {
    setState(() => _acting = n);
    final r = await context.read<AppState>().seatTable(n);
    setState(() => _acting = null);
    if (mounted) showSnack(context, r['success'] == true ? 'Table $n seated ✓' : (r['error'] ?? 'Something went wrong'), error: r['success'] != true);
  }

  Future<void> _reserve(int n) async {
    setState(() => _acting = n);
    final r = await context.read<AppState>().reserveTable(n);
    setState(() => _acting = null);
    if (mounted) showSnack(context, r['success'] == true ? 'Table $n reserved ✓' : (r['error'] ?? 'Something went wrong'), error: r['success'] != true);
  }

  Future<void> _clear(int n) async {
    setState(() => _acting = n);
    final r = await context.read<AppState>().clearTable(n);
    setState(() => _acting = null);
    if (mounted) showSnack(context, r['success'] == true ? 'Table $n cleared ✓' : (r['error'] ?? 'Something went wrong'), error: r['success'] != true);
  }
}
