import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

// ═══════════════════ KITCHEN ═══════════════════

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});
  @override State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  bool _processing = false;
  int _tab = 0;

  Color _typeColor(String type) => switch (type) {
    'prepare' => AppColors.orange, 'cancel' => AppColors.red, 'expedite' => AppColors.green, _ => AppColors.text2,
  };
  String _typeIcon(String type) => switch (type) { 'prepare' => '🔥', 'cancel' => '❌', 'expedite' => '✅', _ => '📋' };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = state.kitchenQueue;
    final pending = (q['pending'] as List<dynamic>?) ?? [];
    final history = (q['history'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Kitchen Navbati', subtitle: 'Command Pattern — execute() / undo() — FIFO navbat'),
        Row(children: [
          StatCard(icon: '📋', value: '${q['pendingCount'] ?? 0}', label: 'Navbatda', iconBg: const Color(0xFFFFF7ED)),
          const SizedBox(width: 14),
          StatCard(icon: '✅', value: '${q['historyCount'] ?? 0}', label: 'Bajarildi', iconBg: const Color(0xFFECFDF5)),
        ].map((w) => Expanded(child: w)).toList()),
        const SizedBox(height: 16),
        Row(children: [
          BpButton(label: '▶ Navbatdagini bajar', loading: _processing,
            onPressed: (q['pendingCount'] ?? 0) == 0 ? null : _processNext,
            bg: AppColors.sidebar, fg: Colors.white),
          const SizedBox(width: 10),
          BpButton(label: '↩ Oxirgini qaytarish', outlined: true,
            onPressed: (q['historyCount'] ?? 0) == 0 ? null : _undoLast),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _tabBtn('Navbat (${q['pendingCount'] ?? 0})', 0),
          const SizedBox(width: 4),
          _tabBtn('Tarix (${q['historyCount'] ?? 0})', 1),
        ]),
        const SizedBox(height: 12),
        if (_tab == 0) ...[
          if (pending.isEmpty)
            BpCard(child: const EmptyState(icon: '✓', message: "Navbat bo'sh — hamma order tayyor"))
          else
            ...pending.map((cmd) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BpCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: _typeColor(cmd['type'] ?? '').withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                    child: Row(children: [
                      Text(_typeIcon(cmd['type'] ?? ''), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text((cmd['type'] ?? '').toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor(cmd['type'] ?? ''))),
                    ]),
                  ),
                  Padding(padding: const EdgeInsets.all(14),
                    child: Text(cmd['description'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
                ]),
              ),
            )),
        ] else ...[
          if (history.isEmpty)
            BpCard(child: const EmptyState(icon: '📋', message: 'Hali bajarilmagan'))
          else
            ...history.reversed.map((cmd) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(opacity: 0.6, child: BpCard(
                child: Row(children: [
                  Text(_typeIcon(cmd['type'] ?? ''), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cmd['description'] ?? '', style: GoogleFonts.inter(fontSize: 13))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('✓ done', style: GoogleFonts.inter(fontSize: 11, color: AppColors.green))),
                ]),
              )),
            )),
        ],
      ]),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? AppColors.border : Colors.transparent),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: active ? AppColors.text : AppColors.text2)),
      ),
    );
  }

  Future<void> _processNext() async {
    setState(() => _processing = true);
    final r = await context.read<AppState>().processKitchen();
    setState(() => _processing = false);
    if (mounted) showSnack(context, r['message'] ?? 'Bajarildi');
  }

  Future<void> _undoLast() async {
    final r = await context.read<AppState>().undoKitchen();
    if (mounted) showSnack(context, r['message'] ?? 'Qaytarildi');
  }
}

// ═══════════════════ BILLING ═══════════════════

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});
  @override State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String? _selectedOrderId;
  String _strategy = 'Standard';
  double _tipPct = 0;
  Map<String, dynamic>? _bill;
  List<double>? _splitShares;
  int _guests = 2;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeOrders = state.orders.where((o) => ['confirmed','preparing','ready'].contains(o['status'])).toList();
    final strats = (state.billingStrategies['available'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: "Hisob & To'lov", subtitle: 'Facade Pattern · Strategy Pattern'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            // Strategy cards
            BpCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Narxlash strategiyasi', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  children: strats.map<Widget>((s) {
                    final active = _strategy == s['name'];
                    return GestureDetector(
                      onTap: () { setState(() => _strategy = s['name']); context.read<AppState>().setStrategy(s['name']); },
                      child: Container(padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFF8F9FF) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: active ? AppColors.sidebar : AppColors.border, width: active ? 1.5 : 1),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(s['description'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text2)),
                          Text((s['discountPercent'] ?? 0) > 0 ? '-${s['discountPercent']}%' : 'Standart',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            // Order selection
            BpCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hisob yaratish', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text('Order tanlash', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _selectedOrderId,
                  hint: Text('— order tanlang —', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), filled: true, fillColor: AppColors.surface),
                  items: activeOrders.map((o) => DropdownMenuItem<String>(
                    value: o['orderId'].toString(),
                    child: Text('${o['orderCode']} — Stol ${o['tableNumber']} (${o['status']}) — £${(o['rawTotal'] ?? 0).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() { _selectedOrderId = v; _bill = null; _splitShares = null; }),
                ),
                const SizedBox(height: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Choy puli: ${_tipPct.toStringAsFixed(0)}%", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
                  Slider(value: _tipPct, min: 0, max: 30, divisions: 6,
                    activeColor: AppColors.sidebar,
                    onChanged: (v) => setState(() => _tipPct = v)),
                ]),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity,
                  child: BpButton(label: '🧾 Hisob yaratish', loading: _generating,
                    onPressed: _selectedOrderId == null ? null : _generate,
                    bg: AppColors.sidebar, fg: Colors.white)),
              ]),
            ),
          ])),
          const SizedBox(width: 16),
          // Bill receipt
          if (_bill != null)
            Expanded(child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), color: AppColors.surface),
              child: Column(children: [
                Container(padding: const EdgeInsets.all(20), width: double.infinity,
                  decoration: const BoxDecoration(color: AppColors.sidebar, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                  child: Column(children: [
                    Text('🍽 BitePlate', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${_bill!['orderCode']} — Stol ${_bill!['tableNumber']}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                  ]),
                ),
                Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                  ...((_bill!['lineItems'] as List<dynamic>?) ?? []).map((li) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text('${li['itemName']} ×${li['quantity']}', style: GoogleFonts.inter(fontSize: 13))),
                      Text('£${(li['lineTotal'] ?? 0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 13)),
                    ]),
                  )),
                  const Divider(height: 20),
                  _billRow('Narx', '£${(_bill!['subtotal'] ?? 0).toStringAsFixed(2)}', color: AppColors.text2),
                  if ((_bill!['discount'] ?? 0) > 0)
                    _billRow('Chegirma (${_bill!['strategyUsed']})', '-£${(_bill!['discount'] ?? 0).toStringAsFixed(2)}', color: AppColors.green),
                  _billRow('Soliq (10%)', '£${(_bill!['tax'] ?? 0).toStringAsFixed(2)}', color: AppColors.text2),
                  if ((_bill!['tip'] ?? 0) > 0)
                    _billRow("Choy puli", '£${(_bill!['tip'] ?? 0).toStringAsFixed(2)}', color: AppColors.text2),
                  const Divider(height: 16),
                  Row(children: [
                    Text('JAMI', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('£${(_bill!['grandTotal'] ?? 0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(
                      initialValue: '2',
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(labelText: 'Mehmonlar', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
                      onChanged: (v) => setState(() => _guests = int.tryParse(v) ?? 2),
                    )),
                    const SizedBox(width: 8),
                    BpButton(label: '÷ Bo\'lish', outlined: true, onPressed: _split),
                  ]),
                  if (_splitShares != null) ...[
                    const SizedBox(height: 10),
                    ...List.generate(_splitShares!.length, (i) => _billRow('Mehmon ${i+1}', '£${_splitShares![i].toStringAsFixed(2)}', color: AppColors.green)),
                  ],
                ])),
              ]),
            )),
        ]),
      ]),
    );
  }

  Widget _billRow(String label, String value, {Color? color}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: color ?? AppColors.text2)),
      const Spacer(),
      Text(value, style: GoogleFonts.inter(fontSize: 13, color: color ?? AppColors.text)),
    ]));
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    final r = await context.read<AppState>().generateBill({
      'orderId': int.parse(_selectedOrderId!),
      'tipPercent': _tipPct,
      'strategy': _strategy,
    });
    setState(() { _generating = false; if (r['success'] == true) _bill = Map<String, dynamic>.from(r['bill']); });
    if (mounted) showSnack(context, r['success'] == true ? 'Hisob yaratildi ✓' : (r['error'] ?? 'Xatolik'), error: r['success'] != true);
  }

  Future<void> _split() async {
    if (_bill == null) return;
    final r = await context.read<AppState>().splitBill((_bill!['grandTotal'] as num).toDouble(), _guests);
    if (r['success'] == true) setState(() => _splitShares = List<double>.from((r['shares'] as List).map((s) => (s as num).toDouble())));
  }
}

// ═══════════════════ HISTORY ═══════════════════

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final h = state.history;
    final records = (h['records'] as List<dynamic>? ?? []).reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Buyurtmalar tarixi', subtitle: 'Singleton Pattern · Iterator Pattern'),
        Row(children: [
          Expanded(child: StatCard(icon: '📋', value: '${h['count'] ?? 0}', label: 'Jami orderlar', iconBg: const Color(0xFFEFF6FF))),
          const SizedBox(width: 14),
          Expanded(child: StatCard(icon: '💷', value: '£${(h['totalRevenue'] ?? 0.0).toStringAsFixed(2)}', label: 'Jami daromad', iconBg: const Color(0xFFECFDF5))),
          const SizedBox(width: 14),
          Expanded(child: StatCard(icon: '⭐', value: h['mostFrequentItem'] ?? '—', label: 'Eng mashhur', iconBg: const Color(0xFFFFF7ED))),
        ]),
        const SizedBox(height: 20),
        BpCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                for (final col in ['Order', 'Stol', 'Xodim', 'Taomlar', 'Jami', 'Status', 'Vaqt'])
                  Expanded(child: Text(col, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.5))),
              ]),
            ),
            const Divider(),
            if (records.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: EmptyState(icon: '📋', message: "Hali buyurtma yo'q"))
            else
              ...records.map((r) => Column(children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    Expanded(child: Text(r['orderCode'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(child: Text('Stol ${r['tableNumber']}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2))),
                    Expanded(child: Text(r['staffName'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2))),
                    Expanded(child: Text((r['itemNames'] as List?)?.take(2).join(', ') ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2), overflow: TextOverflow.ellipsis)),
                    Expanded(child: Text('£${(r['total'] ?? 0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green))),
                    Expanded(child: StatusBadge.forOrderStatus(r['status'] ?? '')),
                    Expanded(child: Text(() { try { return TimeOfDay.fromDateTime(DateTime.parse(r['timestamp'])).format(context); } catch(_) { return ''; } }(), style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2))),
                  ]),
                ),
                const Divider(),
              ])),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════ STAFF ═══════════════════

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  Color _roleColor(String role) => switch (role) {
    'Manager' => AppColors.purple, 'Waiter' => AppColors.blue,
    'Chef' => AppColors.orange, 'Cashier' => AppColors.green, _ => AppColors.text2,
  };

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AppState>().staff;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Xodimlar', subtitle: 'Inheritance · Abstract Staff · Role-based permissions'),
        ...staff.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: BpCard(
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: _roleColor(s['role'] ?? ''),
                child: Text(s['initials'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _roleColor(s['role'] ?? '').withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(s['role'] ?? '', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _roleColor(s['role'] ?? '')))),
                  const SizedBox(width: 8),
                  Text(s['staffId'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 4, runSpacing: 4, children: ((s['permissions'] as List<dynamic>?) ?? []).map((p) =>
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                    child: Text(p.toString(), style: GoogleFonts.inter(fontSize: 10, color: AppColors.text3)))
                ).toList()),
              ])),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ═══════════════════ NOTIFICATIONS ═══════════════════

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(String ts) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(ts));
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) { return ''; }
  }

  Color _typeColor(String type) => switch (type) {
    'order' => AppColors.blue, 'kitchen' => AppColors.orange,
    'billing' => AppColors.gold, 'table' => AppColors.green, _ => AppColors.text2,
  };

  String _typeIcon(String type) => switch (type) { 'order' => '📋', 'kitchen' => '🔥', 'billing' => '💳', 'table' => '🪑', _ => '📢' };

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<AppState>().notifications;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Bildirishnomalar', subtitle: 'Observer Pattern — real-time hodisalar'),
        if (notifs.isEmpty)
          BpCard(child: const EmptyState(icon: '🔕', message: "Hali bildirishnoma yo'q"))
        else
          BpCard(
            padding: EdgeInsets.zero,
            child: Column(children: notifs.map((n) => Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: _typeColor(n['type'] ?? '').withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(_typeIcon(n['type'] ?? ''), style: const TextStyle(fontSize: 16)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['message'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text('${n['type']} · ${_timeAgo(n['timestamp'] ?? '')}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                ])),
              ])),
              const Divider(),
            ])).toList()),
          ),
      ]),
    );
  }
}

// ═══════════════════ MENU PAGE ═══════════════════

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _filter = 'all';
  final List<String> _cats = ['all', 'starter', 'main', 'dessert', 'beverage'];

  Color _catColor(String cat) => switch (cat) {
    'starter' => AppColors.orange, 'main' => AppColors.blue,
    'dessert' => AppColors.gold, 'beverage' => AppColors.green, _ => AppColors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = _filter == 'all' ? state.menu : state.menu.where((m) => m['category'] == _filter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Menyu', subtitle: 'Factory Method Pattern · Decorator Pattern'),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _cats.map((c) {
          final active = _filter == c;
          return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
            onTap: () => setState(() => _filter = c),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: active ? AppColors.sidebar : AppColors.surface, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.sidebar : AppColors.border)),
              child: Text(c == 'all' ? 'Barchasi' : c[0].toUpperCase() + c.substring(1),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.text2))),
          ));
        }).toList())),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final item = filtered[i];
            return BpCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _catColor(item['category'] ?? '').withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(item['category'] ?? '', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _catColor(item['category'] ?? '')))),
              const SizedBox(height: 7),
              Text(item['name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), maxLines: 2),
              const Spacer(),
              Text('£${(item['price'] ?? 0.0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              if ((item['allergens'] as List?)?.isNotEmpty == true)
                Text('⚠ ${(item['allergens'] as List).join(', ')}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.red)),
            ]));
          },
        ),
      ]),
    );
  }
}
