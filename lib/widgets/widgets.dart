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
        borderRadius: BorderRadius.circular(14),
        border: border ?? Border.all(color: AppColors.border),
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: card);
    }
    return card;
  }
}

class StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final String sub;
  final Color iconBg;
  final Color? accentColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.sub = '',
    required this.iconBg,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 19))),
          ),
          const Spacer(),
          if (accentColor != null)
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
            ),
        ]),
        const SizedBox(height: 16),
        Text(value, style: GoogleFonts.spaceGrotesk(
            fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.text, height: 1)),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.spaceGrotesk(
            fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(sub, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
        ],
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

  const BpButton({
    super.key, required this.label, this.onPressed, this.bg, this.fg,
    this.outlined = false, this.small = false, this.icon, this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = bg ?? (outlined ? AppColors.surface2 : AppColors.accent);
    final fgColor = fg ?? (outlined ? AppColors.text : AppColors.accentText);
    return SizedBox(
      height: small ? 34 : 42,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: AppColors.surface3,
          disabledForegroundColor: AppColors.text3,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: outlined ? const BorderSide(color: AppColors.border2) : BorderSide.none,
          ),
        ),
        child: loading
            ? SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fgColor))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[icon!, const SizedBox(width: 7)],
          Text(label, style: GoogleFonts.spaceGrotesk(
              fontSize: small ? 12 : 13, fontWeight: FontWeight.w600)),
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
    return StatusBadge(label: label, bg: AppColors.statusBgColor(status), fg: AppColors.statusColor(status));
  }

  factory StatusBadge.forOrderStatus(String status) {
    return StatusBadge(label: status, bg: AppColors.orderStatusBgColor(status), fg: AppColors.orderStatusColor(status));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
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
        Expanded(child: Text(title, style: GoogleFonts.spaceGrotesk(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text))),
        if (action != null) action!,
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
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

  const BpTextField({
    super.key, required this.label, this.hint, this.controller,
    this.keyboardType, this.enabled = true, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceGrotesk(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType,
        enabled: enabled, validator: validator,
        style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.text3, fontSize: 13),
          filled: true, fillColor: AppColors.surface2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text(message, style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AppColors.text3),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: error ? Colors.white : AppColors.accentText)),
    backgroundColor: error ? AppColors.red : AppColors.green,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  ));
}