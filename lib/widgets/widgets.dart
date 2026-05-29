import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;

  const BpCard({super.key, required this.child, this.padding, this.color, this.onTap, this.border});

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: border ?? Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: child,
    );
    if (onTap != null) return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: card);
    return card;
  }
}

class StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final String sub;
  final Color iconBg;

  const StatCard({super.key, required this.icon, required this.value, required this.label, this.sub = '', required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return BpCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 18)))),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
        if (sub.isNotEmpty) Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
      ]),
    );
  }
}

class BpButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? bg;
  final Color? fg;
  final bool outlined;
  final bool small;
  final Widget? icon;
  final bool loading;

  const BpButton({super.key, required this.label, this.onPressed, this.bg, this.fg, this.outlined = false, this.small = false, this.icon, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = bg ?? (outlined ? AppColors.surface : AppColors.text);
    final fgColor = fg ?? (outlined ? AppColors.text : Colors.white);
    return SizedBox(
      height: small ? 34 : 42,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor, foregroundColor: fgColor,
          elevation: 0, padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: outlined ? const BorderSide(color: AppColors.border2) : BorderSide.none,
          ),
        ),
        child: loading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fgColor))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[icon!, const SizedBox(width: 6)],
                Text(label, style: GoogleFonts.inter(fontSize: small ? 12 : 13, fontWeight: FontWeight.w500)),
              ]),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const StatusBadge({super.key, required this.label, required this.bg, required this.fg});

  factory StatusBadge.forTableStatus(String status) {
    final label = switch (status) {
      'free' => 'Free', 'occupied' => 'Occupied', 'reserved' => 'Reserved',
      'awaitingBill' => 'Awaiting Bill', 'cleared' => 'Cleared', _ => status,
    };
    final bg = switch (status) {
      'free' => const Color(0xFFECFDF5),
      'occupied' => const Color(0xFFFEF2F2),
      'reserved' => const Color(0xFFFFF7ED),
      'awaitingBill' => const Color(0xFFEFF6FF),
      _ => const Color(0xFFF9FAFB),
    };
    final fg = AppColors.statusColor(status);
    return StatusBadge(label: label, bg: bg, fg: fg);
  }

  factory StatusBadge.forOrderStatus(String status) {
    final bg = switch (status) {
      'confirmed' => const Color(0xFFEFF6FF),
      'preparing' => const Color(0xFFFFF7ED),
      'ready' => const Color(0xFFECFDF5),
      'billed' => const Color(0xFFECFDF5),
      'cancelled' => const Color(0xFFFEF2F2),
      'served' => const Color(0xFFF5F3FF),
      _ => const Color(0xFFF9FAFB),
    };
    return StatusBadge(label: status, bg: bg, fg: AppColors.orderStatusColor(status));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text))),
        if (action != null) action!,
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2)),
      ],
      const SizedBox(height: 20),
    ]);
  }
}

class BpTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;

  const BpTextField({super.key, required this.label, this.hint, this.controller, this.keyboardType, this.enabled = true, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
      const SizedBox(height: 5),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.text3),
          filled: true, fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
        ),
      ),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  final String icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(message, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
    ]));
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
    backgroundColor: error ? AppColors.red : AppColors.text,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  ));
}
