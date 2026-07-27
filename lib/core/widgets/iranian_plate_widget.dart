import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/iranian_plate.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Shared compact plate dimensions.
abstract final class _PlateStyle {
  static const double height = 56;
  static const double radius = 12;
  static const double borderWidth = 1.5;
  static const Color outerBorder = Color(0xFF1E293B);
  static const Color divider = Color(0xFFCBD5E1);

  static const double wTwo = 36;
  static const double wLetter = 32;
  static const double wThree = 50;
  static const double wIran = 44;
  static const double wProvince = 36;

  static const TextStyle digitStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0F172A),
    height: 1,
  );

  static const TextStyle letterStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0F172A),
    height: 1,
  );

  static double scaledWidth(double base, double height) => base * (height / _PlateStyle.height);

  static double scaledFontSize(double height) => 17 * (height / _PlateStyle.height);
}

class IranianPlateInput extends StatefulWidget {
  const IranianPlateInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.validator,
  });

  final String? initialValue;
  final ValueChanged<IranianPlateData>? onChanged;
  final String? Function(IranianPlateData?)? validator;

  @override
  State<IranianPlateInput> createState() => IranianPlateInputState();
}

class IranianPlateInputState extends State<IranianPlateInput> {
  late IranianPlateData _data;
  String? _errorText;

  final _twoDigitsController = TextEditingController();
  final _threeDigitsController = TextEditingController();
  final _provinceController = TextEditingController();
  final _twoDigitsFocus = FocusNode();
  final _threeDigitsFocus = FocusNode();
  final _provinceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _data = IranianPlateData.parse(widget.initialValue) ?? const IranianPlateData();
    _twoDigitsController.text = _persian(_data.twoDigits);
    _threeDigitsController.text = _persian(_data.threeDigits);
    _provinceController.text = _persian(_data.provinceCode);
  }

  @override
  void dispose() {
    _twoDigitsController.dispose();
    _threeDigitsController.dispose();
    _provinceController.dispose();
    _twoDigitsFocus.dispose();
    _threeDigitsFocus.dispose();
    _provinceFocus.dispose();
    super.dispose();
  }

  IranianPlateData get data => _data;

  String? validate() {
    final error = widget.validator?.call(_data.isComplete ? _data : null);
    setState(() => _errorText = error);
    return error;
  }

  void _notify() => widget.onChanged?.call(_data);

  String _persian(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(RegExp(r'\d'), (m) => digits[int.parse(m.group(0)!)]);
  }

  String _english(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var result = value;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], '$i').replaceAll(arabic[i], '$i');
    }
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _updateDigits({
    String? twoDigits,
    String? threeDigits,
    String? provinceCode,
  }) {
    setState(() {
      _data = _data.copyWith(
        twoDigits: twoDigits ?? _data.twoDigits,
        threeDigits: threeDigits ?? _data.threeDigits,
        provinceCode: provinceCode ?? _data.provinceCode,
      );
      _errorText = null;
    });
    _notify();
  }

  Future<void> _pickLetter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LetterPickerSheet(selected: _data.letter),
    );

    if (selected != null) {
      setState(() {
        _data = _data.copyWith(letter: selected);
        _errorText = null;
      });
      _notify();
      _threeDigitsFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final borderColor = _errorText != null ? AppTheme.error : _PlateStyle.outerBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.plateNumber,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _PlateFrame(
              borderColor: borderColor,
              children: [
                _PlateDigitField(
                  width: _PlateStyle.wTwo,
                  controller: _twoDigitsController,
                  focusNode: _twoDigitsFocus,
                  maxLength: 2,
                  onChanged: (v) {
                    final digits = _english(v);
                    if (digits.length <= 2) {
                      _twoDigitsController.text = _persian(digits);
                      _twoDigitsController.selection = TextSelection.collapsed(
                        offset: _twoDigitsController.text.length,
                      );
                      _updateDigits(twoDigits: digits);
                      if (digits.length == 2) _pickLetter();
                    }
                  },
                ),
                const _PlateDivider(),
                _PlateLetterField(
                  width: _PlateStyle.wLetter,
                  letter: _data.letter,
                  onTap: _pickLetter,
                ),
                const _PlateDivider(),
                _PlateDigitField(
                  width: _PlateStyle.wThree,
                  controller: _threeDigitsController,
                  focusNode: _threeDigitsFocus,
                  maxLength: 3,
                  onChanged: (v) {
                    final digits = _english(v);
                    if (digits.length <= 3) {
                      _threeDigitsController.text = _persian(digits);
                      _threeDigitsController.selection = TextSelection.collapsed(
                        offset: _threeDigitsController.text.length,
                      );
                      _updateDigits(threeDigits: digits);
                      if (digits.length == 3) _provinceFocus.requestFocus();
                    }
                  },
                ),
                const _PlateDivider(),
                const _PlateIranBand(width: _PlateStyle.wIran, height: _PlateStyle.height),
                const _PlateDivider(),
                _PlateDigitField(
                  width: _PlateStyle.wProvince,
                  controller: _provinceController,
                  focusNode: _provinceFocus,
                  maxLength: 2,
                  background: const Color(0xFFFFFBEB),
                  onChanged: (v) {
                    final digits = _english(v);
                    if (digits.length <= 2) {
                      _provinceController.text = _persian(digits);
                      _provinceController.selection = TextSelection.collapsed(
                        offset: _provinceController.text.length,
                      );
                      _updateDigits(provinceCode: digits);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
        ],
      ],
    );
  }
}

class _PlateFrame extends StatelessWidget {
  const _PlateFrame({
    required this.children,
    required this.borderColor,
    this.height = _PlateStyle.height,
  });

  final List<Widget> children;
  final Color borderColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_PlateStyle.radius),
        border: Border.all(color: borderColor, width: _PlateStyle.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: children,
      ),
    );
  }
}

class _PlateDivider extends StatelessWidget {
  const _PlateDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PlateStyle.borderWidth,
      color: _PlateStyle.divider,
    );
  }
}

class _PlateDigitField extends StatelessWidget {
  const _PlateDigitField({
    required this.width,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.onChanged,
    this.background = Colors.white,
  });

  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ColoredBox(
        color: background,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: _PlateStyle.digitStyle,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[۰-۹0-9]')),
            LengthLimitingTextInputFormatter(maxLength),
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _PlateLetterField extends StatelessWidget {
  const _PlateLetterField({
    required this.width,
    required this.letter,
    required this.onTap,
  });

  final double width;
  final String letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: const Color(0xFFF8FAFC),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              letter.isEmpty ? '·' : letter,
              style: _PlateStyle.letterStyle.copyWith(
                color: letter.isEmpty ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlateIranBand extends StatelessWidget {
  const _PlateIranBand({required this.width, this.height = _PlateStyle.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final stripeH = height * 0.14;
    final stripeW = width * 0.22;
    final iranFontSize = height * 0.15;

    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _flagStripe(const Color(0xFF16A34A), stripeW, stripeH),
              _flagStripe(Colors.white, stripeW, stripeH),
              _flagStripe(const Color(0xFFDC2626), stripeW, stripeH),
            ],
          ),
          SizedBox(height: height * 0.04),
          Text(
            'ایران',
            style: TextStyle(
              color: Colors.white,
              fontSize: iranFontSize.clamp(8, 11),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagStripe(Color color, double w, double h) {
    return Container(width: w, height: h, color: color);
  }
}

class _LetterPickerSheet extends StatelessWidget {
  const _LetterPickerSheet({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.selectPlateLetter,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: IranianPlateLetters.letters.length,
            itemBuilder: (context, index) {
              final letter = IranianPlateLetters.letters[index];
              final isSelected = letter == selected;
              return InkWell(
                onTap: () => Navigator.pop(context, letter),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Read-only plate display (LTR: 12 | ب | 345 | ایران | 66).
class IranianPlateDisplay extends StatelessWidget {
  const IranianPlateDisplay({
    super.key,
    required this.plateNumber,
    this.height = 44,
    this.compact = false,
  });

  final String plateNumber;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final data = IranianPlateData.parse(plateNumber);
    if (data == null) {
      return Text(plateNumber, style: const TextStyle(fontWeight: FontWeight.w600));
    }

    final fontSize = compact
        ? _PlateStyle.scaledFontSize(height) * 0.92
        : _PlateStyle.scaledFontSize(height);

    return Align(
      alignment: Alignment.center,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: _PlateFrame(
          borderColor: _PlateStyle.outerBorder,
          height: height,
          children: [
            _PlateDisplayCell(
              width: _PlateStyle.scaledWidth(_PlateStyle.wTwo, height),
              text: _persian(data.twoDigits),
              fontSize: fontSize,
            ),
            const _PlateDivider(),
            _PlateDisplayCell(
              width: _PlateStyle.scaledWidth(_PlateStyle.wLetter, height),
              text: data.letter,
              fontSize: fontSize,
              background: const Color(0xFFF8FAFC),
            ),
            const _PlateDivider(),
            _PlateDisplayCell(
              width: _PlateStyle.scaledWidth(_PlateStyle.wThree, height),
              text: _persian(data.threeDigits),
              fontSize: fontSize,
            ),
            const _PlateDivider(),
            _PlateIranBand(
              width: _PlateStyle.scaledWidth(_PlateStyle.wIran, height),
              height: height,
            ),
            const _PlateDivider(),
            _PlateDisplayCell(
              width: _PlateStyle.scaledWidth(_PlateStyle.wProvince, height),
              text: _persian(data.provinceCode),
              fontSize: fontSize,
              background: const Color(0xFFFFFBEB),
            ),
          ],
        ),
      ),
    );
  }

  static String _persian(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(RegExp(r'\d'), (m) => digits[int.parse(m.group(0)!)]);
  }
}

class _PlateDisplayCell extends StatelessWidget {
  const _PlateDisplayCell({
    required this.width,
    required this.text,
    required this.fontSize,
    this.background = Colors.white,
  });

  final double width;
  final String text;
  final double fontSize;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ColoredBox(
        color: background,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
