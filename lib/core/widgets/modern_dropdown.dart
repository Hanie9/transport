import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Compact overlay dropdown shared by forms and filters.
///
/// It follows the CRM dropdown visual language while retaining Form validation,
/// dark mode, RTL/LTR positioning and long, scrollable option lists.
class ModernDropdownField<T> extends StatefulWidget {
  const ModernDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.height = 42,
    this.radius = 12,
    this.menuRadius = 12,
    this.fontSize = 13,
  });

  final String label;
  final T? value;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final double height;
  final double radius;
  final double menuRadius;
  final double fontSize;

  static DropdownMenuItem<T> item<T>(
    T value,
    String label, {
    double fontSize = 13,
  }) => DropdownMenuItem<T>(
    value: value,
    child: Text(
      label,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
    ),
  );

  @override
  State<ModernDropdownField<T>> createState() => _ModernDropdownFieldState<T>();
}

class _ModernDropdownFieldState<T> extends State<ModernDropdownField<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _targetKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void didUpdateWidget(covariant ModernDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || widget.onChanged == null) {
      _removeOverlay();
    } else if (_isOpen &&
        (oldWidget.value != widget.value ||
            oldWidget.items.length != widget.items.length)) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeOverlay(updateState: false);
    super.dispose();
  }

  String? _labelForValue(T? value) {
    for (final item in widget.items) {
      if (item.value != value) continue;
      final child = item.child;
      if (child is Text) return child.data ?? child.textSpan?.toPlainText();
      return value?.toString();
    }
    return null;
  }

  void _removeOverlay({bool updateState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen && updateState && mounted) setState(() => _isOpen = false);
    if (!updateState) _isOpen = false;
  }

  void _toggleOverlay(FormFieldState<T> fieldState) {
    if (!widget.enabled || widget.onChanged == null) return;
    if (_isOpen) {
      _removeOverlay();
      return;
    }
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (!keyboardOpen) {
      _showOverlay(fieldState);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isOpen) return;
      _showOverlay(fieldState);
    });
  }

  void _showOverlay(FormFieldState<T> fieldState) {
    final targetContext = _targetKey.currentContext;
    final renderBox = targetContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final overlay = Overlay.of(context);
    final direction = Directionality.of(context);
    final media = MediaQuery.of(context);
    final topLeft = renderBox.localToGlobal(Offset.zero);
    final availableBelow =
        media.size.height - topLeft.dy - renderBox.size.height;
    final availableAbove = topLeft.dy - media.padding.top;
    final desiredHeight = math.min(320.0, widget.items.length * 45.0 + 2);
    final openAbove =
        availableBelow < desiredHeight && availableAbove > availableBelow;
    final start = AlignmentDirectional.centerStart.resolve(direction);
    final targetAnchor = Alignment(start.x, openAbove ? -1 : 1);
    final followerAnchor = Alignment(start.x, openAbove ? 1 : -1);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: Offset(0, openAbove ? -6 : 6),
            child: _DropdownMenuPanel<T>(
              width: renderBox.size.width,
              maxHeight: math.max(
                80,
                math.min(
                  desiredHeight,
                  (openAbove ? availableAbove : availableBelow) - 12,
                ),
              ),
              menuRadius: widget.menuRadius,
              items: widget.items,
              selectedValue: widget.value,
              fontSize: widget.fontSize,
              onSelect: (value) {
                _removeOverlay();
                fieldState.didChange(value);
                widget.onChanged?.call(value);
              },
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ValueKey<String>(
        '${widget.label}::${widget.value}::${widget.items.length}',
      ),
      initialValue: widget.value,
      validator: widget.validator,
      enabled: widget.enabled,
      builder: (fieldState) {
        final palette = context.palette;
        final accent = Theme.of(context).colorScheme.primary;
        final selectedLabel = _labelForValue(widget.value);
        final displayText = selectedLabel ?? widget.label;
        final isHint = selectedLabel == null;
        final hasError = fieldState.hasError;
        final borderColor = hasError
            ? AppTheme.error
            : _isOpen
            ? accent
            : palette.divider;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CompositedTransformTarget(
              key: _targetKey,
              link: _layerLink,
              child: Semantics(
                button: true,
                enabled: widget.enabled && widget.onChanged != null,
                label: widget.label,
                value: selectedLabel,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _toggleOverlay(fieldState),
                    borderRadius: BorderRadius.circular(widget.radius),
                    child: Ink(
                      height: widget.height,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: palette.cardBg,
                        borderRadius: BorderRadius.circular(widget.radius),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            if (widget.prefixIcon != null) ...[
                              Icon(
                                widget.prefixIcon,
                                size: 19,
                                color: _isOpen ? accent : palette.textSecondary,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                displayText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: widget.fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: isHint
                                      ? palette.textSecondary.withValues(
                                          alpha: widget.enabled ? 0.85 : 0.5,
                                        )
                                      : palette.textPrimary.withValues(
                                          alpha: widget.enabled ? 1 : 0.5,
                                        ),
                                ),
                              ),
                            ),
                            Icon(
                              _isOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: palette.textSecondary.withValues(
                                alpha: widget.enabled ? 0.85 : 0.45,
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
            if (hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: Text(
                  fieldState.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DropdownMenuPanel<T> extends StatelessWidget {
  const _DropdownMenuPanel({
    required this.width,
    required this.maxHeight,
    required this.menuRadius,
    required this.items,
    required this.selectedValue,
    required this.fontSize,
    required this.onSelect,
  });

  final double width;
  final double maxHeight;
  final double menuRadius;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final double fontSize;
  final ValueChanged<T?> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: palette.cardBg,
      borderRadius: BorderRadius.circular(menuRadius),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(menuRadius),
          border: Border.all(color: palette.divider),
        ),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            thickness: 1,
            color: palette.divider.withValues(alpha: 0.7),
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.value == selectedValue;
            return Material(
              color: selected
                  ? accent.withValues(alpha: 0.08)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(item.value),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: selected ? accent : palette.textPrimary,
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(
                          size: 19,
                          color: selected ? accent : palette.textSecondary,
                        ),
                        child: item.child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
