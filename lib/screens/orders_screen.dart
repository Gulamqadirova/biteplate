import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrderItem {
  final int menuIndex;
  final String label;
  final double price;
  final String? toppingName;
  final double? toppingCost;
  final String? specialInstruction;

  _OrderItem({required this.menuIndex, required this.label, required this.price, this.toppingName, this.toppingCost, this.specialInstruction});

  double get total => price + (toppingCost ?? 0);
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _tableNum = '1';
  String _staffId = 'WTR01';
  String _filter = 'all';
  final List<_OrderItem> _items = [];
  bool _placing = false;
  String? _lastOrderCode;

  final List<String> _cats = ['all', 'starter', 'main', 'dessert', 'beverage'];
  final List<List<String>> _staffList = [['WTR01','Bob Smith'],['WTR02','Carol Davis'],['WTR03','Mike Brown']];

  Color _catColor(String cat) => switch (cat) {
    'starter' => AppColors.orange, 'main' => AppColors.blue,
    'dessert' => AppColors.gold, 'beverage' => AppColors.green, _ => AppColors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = _filter == 'all' ? state.menu : state.menu.where((m) => m['category'] == _filter).toList();
    final rawTotal = _items.fold(0.0, (s, i) => s + i.total);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Menu side
      Expanded(
        flex: 6,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Orderlar', subtitle: 'Observer · Command · Decorator Pattern'),
            // Config row
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stol', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _tableNum,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    filled: true, fillColor: AppColors.surface,
                  ),
                  items: List.generate(12, (i) => DropdownMenuItem(value: '${i+1}', child: Text('Stol ${i+1}', style: GoogleFonts.inter(fontSize: 13)))),
                  onChanged: (v) => setState(() => _tableNum = v!),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Xodim', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _staffId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    filled: true, fillColor: AppColors.surface,
                  ),
                  items: _staffList.map((s) => DropdownMenuItem(value: s[0], child: Text(s[1], style: GoogleFonts.inter(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _staffId = v!),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            // Category filter
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _cats.map((c) {
              final active = _filter == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.sidebar : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.sidebar : AppColors.border),
                    ),
                    child: Text(c == 'all' ? 'Barchasi' : c[0].toUpperCase() + c.substring(1),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.text2)),
                  ),
                ),
              );
            }).toList())),
            const SizedBox(height: 16),
            // Menu grid
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final item = filtered[i];
                return GestureDetector(
                  onTap: () => _showCustomiseModal(item),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: _catColor(item['category'] ?? '').withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(item['category'] ?? '', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _catColor(item['category'] ?? ''))),
                      ),
                      const SizedBox(height: 7),
                      Text(item['name'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), maxLines: 2),
                      const Spacer(),
                      Text('£${(item['price'] ?? 0.0).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                      if ((item['allergens'] as List?)?.isNotEmpty == true)
                        Text('⚠ ${(item['allergens'] as List).join(', ')}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.red)),
                    ]),
                  ),
                );
              },
            ),
          ]),
        ),
      ),

      // Order builder
      Container(
        width: 320,
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(left: BorderSide(color: AppColors.border))),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16),
            child: Text('🛒 Buyurtma', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
          const Divider(),
          Expanded(
            child: _items.isEmpty
                ? const EmptyState(icon: '👆', message: 'Taom bosing qo\'shish uchun')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                            if (item.toppingName != null) Text('+ ${item.toppingName}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.gold)),
                            if (item.specialInstruction != null) Text('>> ${item.specialInstruction}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.blue)),
                          ])),
                          Text('£${item.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          GestureDetector(onTap: () => setState(() => _items.removeAt(i)),
                            child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.close, size: 14, color: AppColors.red))),
                        ]),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Row(children: [
              Text('Jami', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('£${rawTotal.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: BpButton(label: '🚀 Orderlarni yuborish', loading: _placing, onPressed: _items.isEmpty ? null : _placeOrder,
                bg: AppColors.sidebar, fg: Colors.white)),
            if (_lastOrderCode != null) ...[
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.green.withOpacity(0.3))),
                child: Text('✓ $_lastOrderCode kitchen navbatiga qo\'shildi', style: GoogleFonts.inter(fontSize: 12, color: AppColors.green))),
            ],
          ])),
        ]),
      ),
    ]);
  }

  void _showCustomiseModal(Map item) {
    final toppingCtrl = TextEditingController();
    final toppingCostCtrl = TextEditingController();
    final instrCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text("Maxsus: ${item['name']}", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        BpTextField(label: "Qo'shimcha topping", hint: 'masalan: Limon sousi', controller: toppingCtrl),
        const SizedBox(height: 12),
        BpTextField(label: 'Topping narxi (£)', hint: '0.00', controller: toppingCostCtrl, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        BpTextField(label: 'Maxsus tayyorlash', hint: 'masalan: terisiz, yaxshi pishirilgan', controller: instrCtrl),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
        ElevatedButton(
          onPressed: () {
            final topping = toppingCtrl.text.trim();
            final cost = double.tryParse(toppingCostCtrl.text) ?? 0;
            final instr = instrCtrl.text.trim();
            setState(() => _items.add(_OrderItem(
              menuIndex: item['menuIndex'] as int,
              label: item['name'] as String,
              price: (item['price'] as num).toDouble(),
              toppingName: topping.isEmpty ? null : topping,
              toppingCost: topping.isEmpty ? null : (cost > 0 ? cost : null),
              specialInstruction: instr.isEmpty ? null : instr,
            )));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sidebar, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text('+ Qo\'shish', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        ),
      ],
    ));
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) return;
    setState(() => _placing = true);
    final r = await context.read<AppState>().placeOrder({
      'tableNumber': int.parse(_tableNum),
      'staffId': _staffId,
      'items': _items.map((i) => {
        'menuIndex': i.menuIndex, 'quantity': 1,
        if (i.toppingName != null) 'toppingName': i.toppingName,
        if (i.toppingCost != null) 'toppingCost': i.toppingCost,
        if (i.specialInstruction != null) 'specialInstruction': i.specialInstruction,
      }).toList(),
    });
    setState(() { _placing = false; });
    if (r['success'] == true) {
      setState(() { _lastOrderCode = r['order']['orderCode']; _items.clear(); });
      if (mounted) showSnack(context, 'Order qabul qilindi ✓');
    } else {
      if (mounted) showSnack(context, r['error'] ?? 'Xatolik', error: true);
    }
  }
}
