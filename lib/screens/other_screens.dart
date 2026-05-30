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
    'prepare' => AppColors.orange, 'cancel' => AppColors.red,
    'expedite' => AppColors.accent, _ => AppColors.text2,
  };
  String _typeIcon(String type) => switch (type) {
    'prepare' => '🔥', 'cancel' => '✕', 'expedite' => '⚡', _ => '📋'
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = state.kitchenQueue;
    final pending = (q['pending'] as List<dynamic>?) ?? [];
    final history = (q['history'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Kitchen Queue', subtitle: 'Command pattern — execute() / undo() over a FIFO queue'),
        Row(children: [
          Expanded(child: StatCard(icon: '📋', value: '${q['pendingCount'] ?? 0}', label: 'In Queue',
              iconBg: AppColors.orangeDim, accentColor: AppColors.orange)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: '✅', value: '${q['historyCount'] ?? 0}', label: 'Completed',
              iconBg: AppColors.greenDim, accentColor: AppColors.green)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          BpButton(
            label: 'Process Next', loading: _processing,
            icon: const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.accentText),
            onPressed: (q['pendingCount'] ?? 0) == 0 ? null : _processNext,
            bg: AppColors.accent, fg: AppColors.accentText,
          ),
          const SizedBox(width: 10),
          BpButton(
            label: 'Undo Last', outlined: true,
            icon: const Icon(Icons.undo_rounded, size: 16, color: AppColors.text),
            onPressed: (q['historyCount'] ?? 0) == 0 ? null : _undoLast,
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _tabBtn('Queue (${q['pendingCount'] ?? 0})', 0),
          const SizedBox(width: 6),
          _tabBtn('History (${q['historyCount'] ?? 0})', 1),
        ]),
        const SizedBox(height: 12),
        if (_tab == 0) ...[
          if (pending.isEmpty)
            BpCard(child: const EmptyState(icon: '✓', message: 'Queue is empty — all caught up'))
          else
            ...pending.map((cmd) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BpCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _typeColor(cmd['type'] ?? '').withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(children: [
                      Text(_typeIcon(cmd['type'] ?? ''), style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text((cmd['type'] ?? '').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700,
                              letterSpacing: 0.8, color: _typeColor(cmd['type'] ?? ''))),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Align(alignment: Alignment.centerLeft,
                        child: Text(cmd['description'] ?? '',
                            style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text))),
                  ),
                ]),
              ),
            )),
        ] else ...[
          if (history.isEmpty)
            BpCard(child: const EmptyState(icon: '📋', message: 'Nothing processed yet'))
          else
            ...history.reversed.map((cmd) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(opacity: 0.6, child: BpCard(
                child: Row(children: [
                  Text(_typeIcon(cmd['type'] ?? ''), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cmd['description'] ?? '',
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text2))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.greenDim, borderRadius: BorderRadius.circular(20)),
                    child: Text('done', style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green)),
                  ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.spaceGrotesk(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? AppColors.accent : AppColors.text2)),
      ),
    );
  }

  Future<void> _processNext() async {
    setState(() => _processing = true);
    final r = await context.read<AppState>().processKitchen();
    setState(() => _processing = false);
    if (mounted) showSnack(context, r['message'] ?? 'Done');
  }

  Future<void> _undoLast() async {
    final r = await context.read<AppState>().undoKitchen();
    if (mounted) showSnack(context, r['message'] ?? 'Undone');
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
    final activeOrders = state.orders
        .where((o) => ['confirmed', 'preparing', 'ready', 'served'].contains(o['status']))
        .toList();
    final strats = (state.billingStrategies['available'] as List<dynamic>?) ?? [];

    // Fix: validate selectedOrderId exists in current list
    final validId = activeOrders.any((o) => o['orderId'].toString() == _selectedOrderId)
        ? _selectedOrderId
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Billing & POS', subtitle: 'Facade pattern over the Strategy pricing engine'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            // Strategy cards
            BpCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pricing Strategy', style: GoogleFonts.spaceGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, childAspectRatio: 2.2,
                  crossAxisSpacing: 8, mainAxisSpacing: 8,
                  children: strats.map<Widget>((s) {
                    final active = _strategy == s['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _strategy = s['name']);
                        context.read<AppState>().setStrategy(s['name']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: active ? AppColors.accentDim : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: active ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
                              width: active ? 1.5 : 1),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(s['name'] ?? '', style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                              Text(s['description'] ?? '', style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10, color: AppColors.text3),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text((s['discountPercent'] ?? 0) > 0 ? '−${s['discountPercent']}%' : 'Standard',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
                            ]),
                      ),
                    );
                  }).toList(),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // Order selection
            BpCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Generate Bill', style: GoogleFonts.spaceGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 12),
                Text('Select an order', style: GoogleFonts.spaceGrotesk(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: validId,
                  isExpanded: true,
                  dropdownColor: AppColors.surface2,
                  hint: Text('— choose an order —', style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, color: AppColors.text3)),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border2)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    filled: true, fillColor: AppColors.surface2,
                  ),
                  style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text),
                  items: activeOrders.map((o) => DropdownMenuItem<String>(
                    value: o['orderId'].toString(),
                    child: Text(
                      '${o['orderCode']} — Table ${o['tableNumber']} · £${(o['rawTotal'] ?? 0).toStringAsFixed(2)}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() {
                    _selectedOrderId = v;
                    _bill = null;
                    _splitShares = null;
                  }),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Text('Tip: ${_tipPct.toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
                ]),
                Slider(
                  value: _tipPct, min: 0, max: 30, divisions: 6,
                  onChanged: (v) => setState(() => _tipPct = v),
                ),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity,
                    child: BpButton(
                      label: 'Generate Bill', loading: _generating,
                      icon: const Icon(Icons.receipt_long_rounded, size: 15, color: AppColors.accentText),
                      onPressed: validId == null ? null : _generate,
                      bg: AppColors.accent, fg: AppColors.accentText,
                    )),
              ]),
            ),
          ])),
          const SizedBox(width: 16),
          // Bill receipt
          if (_bill != null)
            Expanded(child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(20), width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Column(children: [
                    Text('BitePlate', style: GoogleFonts.spaceGrotesk(
                        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    const SizedBox(height: 4),
                    Text('${_bill!['orderCode']} — Table ${_bill!['tableNumber']}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
                  ]),
                ),
                Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                  ...((_bill!['lineItems'] as List<dynamic>?) ?? []).map((li) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text('${li['itemName']} ×${li['quantity']}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text))),
                      Text('£${(li['lineTotal'] ?? 0).toStringAsFixed(2)}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text)),
                    ]),
                  )),
                  const Divider(height: 20),
                  _billRow('Subtotal', '£${(_bill!['subtotal'] ?? 0).toStringAsFixed(2)}', color: AppColors.text2),
                  if ((_bill!['discount'] ?? 0) > 0)
                    _billRow('Discount', '−£${(_bill!['discount'] ?? 0).toStringAsFixed(2)}', color: AppColors.green),
                  _billRow('Tax (10%)', '£${(_bill!['tax'] ?? 0).toStringAsFixed(2)}', color: AppColors.text2),
                  if ((_bill!['tip'] ?? 0) > 0)
                    _billRow('Tip', '£${(_bill!['tip'] ?? 0).toStringAsFixed(2)}', color: AppColors.text2),
                  if (_bill!['perk'] != null)
                    _billRow('Perk', _bill!['perk'].toString(), color: AppColors.purple),
                  const Divider(height: 16),
                  Row(children: [
                    Text('TOTAL', style: GoogleFonts.spaceGrotesk(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const Spacer(),
                    Text('£${(_bill!['grandTotal'] ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(
                      initialValue: '2',
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Guests',
                        labelStyle: GoogleFonts.spaceGrotesk(color: AppColors.text2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true, fillColor: AppColors.surface2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      ),
                      onChanged: (v) => setState(() => _guests = int.tryParse(v) ?? 2),
                    )),
                    const SizedBox(width: 8),
                    BpButton(label: 'Split Bill', outlined: true, onPressed: _split),
                  ]),
                  if (_splitShares != null) ...[
                    const SizedBox(height: 10),
                    ...List.generate(_splitShares!.length, (i) =>
                        _billRow('Guest ${i + 1}', '£${_splitShares![i].toStringAsFixed(2)}', color: AppColors.green)),
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
      Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: color ?? AppColors.text2)),
      const Spacer(),
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: color ?? AppColors.text)),
    ]));
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    final r = await context.read<AppState>().generateBill({
      'orderId': int.parse(_selectedOrderId!),
      'tipPercent': _tipPct,
      'strategy': _strategy,
    });
    setState(() {
      _generating = false;
      if (r['success'] == true) _bill = Map<String, dynamic>.from(r['bill']);
    });
    if (mounted) showSnack(context,
        r['success'] == true ? 'Bill generated ✓' : (r['error'] ?? 'Something went wrong'),
        error: r['success'] != true);
  }

  Future<void> _split() async {
    if (_bill == null) return;
    final r = await context.read<AppState>().splitBill(
        (_bill!['grandTotal'] as num).toDouble(), _guests);
    if (r['success'] == true) {
      setState(() => _splitShares =
      List<double>.from((r['shares'] as List).map((s) => (s as num).toDouble())));
    }
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
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Order History', subtitle: 'Singleton audit log traversed via the Iterator pattern'),
        Row(children: [
          Expanded(child: StatCard(icon: '📋', value: '${h['count'] ?? 0}', label: 'Total Orders',
              iconBg: AppColors.blueDim, accentColor: AppColors.blue)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: '💷', value: '£${(h['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
              label: 'Total Revenue', iconBg: AppColors.greenDim, accentColor: AppColors.green)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: '⭐', value: h['mostFrequentItem'] ?? '—',
              label: 'Top Dish', iconBg: AppColors.yellowDim, accentColor: AppColors.yellow)),
        ]),
        const SizedBox(height: 20),
        BpCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                for (final col in ['Order', 'Table', 'Staff', 'Items', 'Total', 'Status', 'Time'])
                  Expanded(child: Text(col, style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.text3, letterSpacing: 0.5))),
              ]),
            ),
            Container(height: 1, color: AppColors.border),
            if (records.isEmpty)
              const Padding(padding: EdgeInsets.all(32),
                  child: EmptyState(icon: '📋', message: 'No orders recorded yet'))
            else
              ...records.map((r) => Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    Expanded(child: Text(r['orderCode'] ?? '', style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text))),
                    Expanded(child: Text('Table ${r['tableNumber']}', style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, color: AppColors.text2))),
                    Expanded(child: Text(r['staffName'] ?? '', style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, color: AppColors.text2))),
                    Expanded(child: Text((r['itemNames'] as List?)?.take(2).join(', ') ?? '',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text2),
                        overflow: TextOverflow.ellipsis)),
                    Expanded(child: Text('£${(r['total'] ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green))),
                    Expanded(child: StatusBadge.forOrderStatus(r['status'] ?? '')),
                    Expanded(child: Text(() {
                      try { return TimeOfDay.fromDateTime(DateTime.parse(r['timestamp'])).format(context); }
                      catch (_) { return ''; }
                    }(), style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text2))),
                  ]),
                ),
                Container(height: 1, color: AppColors.border),
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

  Color _roleBg(String role) => switch (role) {
    'Manager' => AppColors.purpleDim, 'Waiter' => AppColors.blueDim,
    'Chef' => AppColors.orangeDim, 'Cashier' => AppColors.greenDim, _ => AppColors.surface2,
  };

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AppState>().staff;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Staff & Roles',
            subtitle: 'Inheritance + role-based permissions (abstract Staff base class)'),
        ...staff.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: BpCard(
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _roleBg(s['role'] ?? ''),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(s['initials'] ?? '', style: GoogleFonts.spaceGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _roleColor(s['role'] ?? '')))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s['name'] ?? '', style: GoogleFonts.spaceGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _roleBg(s['role'] ?? ''), borderRadius: BorderRadius.circular(20)),
                    child: Text(s['role'] ?? '', style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor(s['role'] ?? ''))),
                  ),
                  const SizedBox(width: 8),
                  Text(s['staffId'] ?? '', style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, color: AppColors.text3)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 4, runSpacing: 4,
                    children: ((s['permissions'] as List<dynamic>?) ?? []).map((p) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border)),
                          child: Text(p.toString(), style: GoogleFonts.spaceGrotesk(
                              fontSize: 10, color: AppColors.text3)),
                        )).toList()),
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
    'billing' => AppColors.yellow, 'table' => AppColors.green,
    'alert' => AppColors.red, _ => AppColors.text2,
  };

  Color _typeBg(String type) => switch (type) {
    'order' => AppColors.blueDim, 'kitchen' => AppColors.orangeDim,
    'billing' => AppColors.yellowDim, 'table' => AppColors.greenDim,
    'alert' => AppColors.redDim, _ => AppColors.surface2,
  };

  String _typeIcon(String type) => switch (type) {
    'order' => '📋', 'kitchen' => '🔥', 'billing' => '💳',
    'table' => '🪑', 'alert' => '⚠️', _ => '📢',
  };

  @override
  Widget build(BuildContext context) {
    final notifs = context.watch<AppState>().notifications;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Notifications',
            subtitle: 'Observer pattern — one event fans out to every subscribed recipient'),
        if (notifs.isEmpty)
          BpCard(child: const EmptyState(icon: '🔔', message: 'No notifications yet'))
        else
          BpCard(
            padding: EdgeInsets.zero,
            child: Column(children: notifs.map((n) => Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: _typeBg(n['type'] ?? ''),
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(_typeIcon(n['type'] ?? ''),
                        style: const TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['message'] ?? '', style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, color: AppColors.text)),
                    const SizedBox(height: 3),
                    Text('${n['type']} · ${_timeAgo(n['timestamp'] ?? '')}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
                  ])),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                        color: _typeColor(n['type'] ?? ''), shape: BoxShape.circle),
                  ),
                ]),
              ),
              Container(height: 1, color: AppColors.border),
            ])).toList()),
          ),
      ]),
    );
  }
}

// ═══════════════════ MENU ═══════════════════

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _filter = 'all';
  final List<String> _cats = ['all', 'starter', 'main', 'dessert', 'beverage'];

  String _catLabel(String c) => switch (c) {
    'all' => 'All', 'starter' => 'Starters', 'main' => 'Mains',
    'dessert' => 'Desserts', 'beverage' => 'Beverages', _ => c,
  };

  Color _catColor(String cat) => switch (cat) {
    'starter' => AppColors.orange, 'main' => AppColors.blue,
    'dessert' => AppColors.yellow, 'beverage' => AppColors.green, _ => AppColors.purple,
  };

  Color _catBg(String cat) => switch (cat) {
    'starter' => AppColors.orangeDim, 'main' => AppColors.blueDim,
    'dessert' => AppColors.yellowDim, 'beverage' => AppColors.greenDim, _ => AppColors.purpleDim,
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = _filter == 'all'
        ? state.menu
        : state.menu.where((m) => m['category'] == _filter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Menu', subtitle: 'Factory Method · Composite · Decorator patterns'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _cats.map((c) {
            final active = _filter == c;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accentDim : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border),
                  ),
                  child: Text(_catLabel(c), style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? AppColors.accent : AppColors.text2)),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final item = filtered[i];
            final cat = item['category'] ?? '';
            return BpCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _catBg(cat), borderRadius: BorderRadius.circular(20)),
                  child: Text(cat, style: GoogleFonts.spaceGrotesk(
                      fontSize: 10, fontWeight: FontWeight.w700, color: _catColor(cat))),
                ),
                const SizedBox(height: 8),
                Text(item['name'] ?? '', style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), maxLines: 2),
                const Spacer(),
                Text('£${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent)),
                if ((item['allergens'] as List?)?.isNotEmpty == true)
                  Text('⚠ ${(item['allergens'] as List).join(', ')}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.red)),
              ]),
            );
          },
        ),
      ]),
    );
  }
}