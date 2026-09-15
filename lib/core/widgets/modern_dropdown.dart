import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared Material 3 dropdown used across forms and filters.
class ModernDropdownField<T> extends StatelessWidget {
  const ModernDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return DropdownButtonFormField<T>(
      key: ValueKey<String>('$label::$value::${items.length}'),
      initialValue: value,
      isExpanded: true,
      elevation: 10,
      menuMaxHeight: 360,
      borderRadius: BorderRadius.circular(18),
      dropdownColor: palette.cardBg,
      alignment: AlignmentDirectional.centerStart,
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 22),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Icon(prefixIcon, color: accent),
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 44),
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
