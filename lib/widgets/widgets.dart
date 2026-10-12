import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── TmCard ────────────────────────────────────────────────────
class TmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const TmCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );
}

// ── TmInput ───────────────────────────────────────────────────
class TmInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLines;
  final bool enabled;

  const TmInput({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: textInputAction,
        obscureText: obscureText,
        maxLines: maxLines,
        enabled: enabled,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textSecondary),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: AppTheme.textSecondary) : null,
          suffixIcon: suffixIcon != null
              ? GestureDetector(onTap: onSuffixTap, child: Icon(suffixIcon, size: 18, color: AppTheme.textSecondary))
              : null,
          filled: true,
          fillColor: AppTheme.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      );
}

// ── TmButton ──────────────────────────────────────────────────
class TmButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foreground;
  final bool fullWidth;
  final bool loading;

  const TmButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
    this.foreground,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
      label: Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppTheme.primary,
        foregroundColor: foreground ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ── ResultRow ─────────────────────────────────────────────────
class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const ResultRow({super.key, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textSecondary)),
            Text(value,
                style: GoogleFonts.syne(
                  fontSize: highlight ? 15 : 13,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight ? AppTheme.primary : AppTheme.textPrimary,
                )),
          ],
        ),
      );
}

// ── TmBadge ───────────────────────────────────────────────────
class TmBadge extends StatelessWidget {
  final String label;
  final Color color;

  const TmBadge({super.key, required this.label, this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );
}

// ── TmEmptyState ──────────────────────────────────────────────
class TmEmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String message;
  final Widget? action;

  const TmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      );
}

// ── Snack unificado ───────────────────────────────────────────
void showTmSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppTheme.danger : AppTheme.success,
      duration: const Duration(seconds: 2),
    ));
}
