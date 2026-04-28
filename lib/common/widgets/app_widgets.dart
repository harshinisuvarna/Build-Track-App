import 'package:buildtrack_mobile/common/themes/app_theme.dart';
import 'package:flutter/material.dart';

/// Reusable UI components for BuildTrack.
/// No business logic — pure presentation widgets only.

// ─────────────────────────────────────────────────────────────────────────────
// 1. AppCard
// ─────────────────────────────────────────────────────────────────────────────

/// A white, rounded card with a subtle shadow.
/// Wrap any content inside it for a consistent card look.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingMd),
    this.margin = const EdgeInsets.only(bottom: AppTheme.spacingMd),
    this.color = AppTheme.surface,
    this.borderRadius = AppTheme.radiusLg,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppTheme.cardShadows,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. AppButton
// ─────────────────────────────────────────────────────────────────────────────

enum AppButtonVariant { primary, secondary, outline, danger }

/// Full-width, themed button with optional leading icon.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _resolveColors();

    return SizedBox(
      width: double.infinity,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: variant == AppButtonVariant.outline ? Colors.transparent : bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: variant == AppButtonVariant.outline
                ? Border.all(color: border, width: 1.5)
                : null,
            boxShadow: (variant == AppButtonVariant.primary && enabled)
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: (enabled && !isLoading) ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fg,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: fg, size: 18),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: fg,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg, Color border) _resolveColors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return (AppTheme.primary, Colors.white, AppTheme.primary);
      case AppButtonVariant.secondary:
        return (AppTheme.secondary, Colors.white, AppTheme.secondary);
      case AppButtonVariant.outline:
        return (Colors.transparent, AppTheme.primary, AppTheme.primary);
      case AppButtonVariant.danger:
        return (const Color(0xFFFEE2E2), AppTheme.error, const Color(0xFFFEE2E2));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. AppTextField
// ─────────────────────────────────────────────────────────────────────────────

/// A styled text input with label, hint, and optional prefix/suffix icon.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.label.copyWith(color: AppTheme.textMedium),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textDark),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppTheme.textLight, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? AppTheme.surface : AppTheme.background,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. AppDropdownField
// ─────────────────────────────────────────────────────────────────────────────

/// A styled dropdown field that matches AppTextField visually.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.label.copyWith(color: AppTheme.textMedium),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.divider, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: hint != null
                  ? Text(hint!, style: AppTheme.body.copyWith(color: AppTheme.textLight))
                  : null,
              items: items,
              onChanged: onChanged,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textDark),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textLight),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. AppStatusBadge
// ─────────────────────────────────────────────────────────────────────────────

enum AppStatus { completed, inProgress, notStarted, delayed, issue }

/// Color-coded status pill following the SRS color system.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.status});

  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (String label, Color bg, Color fg) _resolve() {
    switch (status) {
      case AppStatus.completed:
        return ('Completed', const Color(0xFFDCFCE7), AppTheme.success);
      case AppStatus.inProgress:
        return ('In Progress', const Color(0xFFFEF9C3), const Color(0xFFB45309));
      case AppStatus.notStarted:
        return ('Not Started', const Color(0xFFF1F5F9), AppTheme.textMedium);
      case AppStatus.delayed:
        return ('Delayed', const Color(0xFFFEE2E2), AppTheme.error);
      case AppStatus.issue:
        return ('Issue', const Color(0xFFFFF7ED), const Color(0xFFEA580C));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. AppSectionHeader
// ─────────────────────────────────────────────────────────────────────────────

/// A labelled section header with an optional action button.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.heading3),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTheme.body.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. AppDivider
// ─────────────────────────────────────────────────────────────────────────────

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.verticalPadding = AppTheme.spacingMd});

  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: const Divider(color: AppTheme.divider, thickness: 1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. AppProgressBar
// ─────────────────────────────────────────────────────────────────────────────

/// Labelled horizontal progress bar with percentage text.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.label,
    required this.percent,
    this.color = AppTheme.secondary,
  });

  final String label;
  final double percent; // 0.0 – 1.0
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body),
            Text(
              '${(percent * 100).round()}%',
              style: AppTheme.body.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 7,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. AppEmptyState
// ─────────────────────────────────────────────────────────────────────────────

/// Shown when a list or section has no data.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppTheme.textLight),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              message,
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. StatusBadge
// ─────────────────────────────────────────────────────────────────────────────

/// Displays entry status as a compact, colored pill badge.
///
/// Usage:
///   StatusBadge(status: 'pending')
///   StatusBadge(status: 'approved')
///   StatusBadge(status: 'rejected')
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  Color get _color {
    switch (status) {
      case 'approved': return const Color(0xFF2E7D32);
      case 'rejected': return const Color(0xFFC62828);
      default:         return const Color(0xFFE65100); // pending → orange
    }
  }

  Color get _bg {
    switch (status) {
      case 'approved': return const Color(0xFFE8F5E9);
      case 'rejected': return const Color(0xFFFFEBEE);
      default:         return const Color(0xFFFFF3E0);
    }
  }

  IconData get _icon {
    switch (status) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default:         return Icons.hourglass_empty_outlined;
    }
  }

  String get _label {
    switch (status) {
      case 'approved': return 'APPROVED';
      case 'rejected': return 'REJECTED';
      default:         return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 12),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
