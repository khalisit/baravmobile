import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// خانەی نووسین لەگەڵ ئەنیمەیشنی فۆکەس — چوارچێوەکە نەوشەیی دەبێت و دەدرەوشێتەوە.
class BaravTextField extends StatefulWidget {
  const BaravTextField({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.focusNode,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.inputFormatters,
    this.ltr = false,
    this.verticalPadding = 15,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
    this.maxLength,
    this.errorText,
    this.helperText,
    this.suffixIcon,
    this.onChanged,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final int? maxLength;
  final String? errorText;
  final String? helperText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  /// بۆ ئیمەیڵ، وشەی نهێنی و ژمارە — نووسین لە چەپەوە بۆ ڕاست دەڕوات.
  final bool ltr;

  /// بەرزی خانەکە لەگەڵ قەبارەی شاشە دەگونجێنێت.
  final double verticalPadding;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  @override
  State<BaravTextField> createState() => _BaravTextFieldState();
}

class _BaravTextFieldState extends State<BaravTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _focused = false;
  bool _hidden = true;

  FormFieldState<String>? _fieldState;

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _onControllerChanged() {
    if (widget.controller != null && _fieldState != null) {
      if (_fieldState!.value != widget.controller!.text) {
        _fieldState!.didChange(widget.controller!.text);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller?.removeListener(_onControllerChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final obscured = widget.obscure && _hidden;

    return FormField<String>(
      initialValue: widget.controller?.text ?? '',
      validator: widget.validator,
      builder: (FormFieldState<String> state) {
        _fieldState = state;
        final hasError = state.hasError || widget.errorText != null;
        final errorString = state.errorText ?? widget.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: theme.textTheme.labelMedium!.copyWith(
                  color: hasError
                      ? AppColors.danger
                      : (_focused ? AppColors.purpleLight : colors.textMuted),
                ),
                child: Text(widget.label),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _focused ? colors.surfaceHigh : colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasError
                      ? AppColors.danger
                      : (_focused ? AppColors.purple : colors.stroke),
                  width: _focused || hasError ? 1.4 : 1,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: (hasError ? AppColors.danger : AppColors.purple)
                              .withValues(alpha: 0.26),
                          blurRadius: 22,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Directionality(
                textDirection: widget.ltr ? TextDirection.ltr : Directionality.of(context),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: obscured,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  maxLength: widget.maxLength,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                  onSubmitted: (val) {
                    if (widget.textInputAction == TextInputAction.next) {
                      FocusScope.of(context).nextFocus();
                    } else if (widget.textInputAction == TextInputAction.done) {
                      FocusScope.of(context).unfocus();
                    }
                    if (widget.onSubmitted != null) widget.onSubmitted!(val);
                  },
                  onChanged: (val) {
                    state.didChange(val);
                    if (widget.onChanged != null) widget.onChanged!(val);
                  },
                  textDirection: widget.ltr ? TextDirection.ltr : null,
                  textAlign: widget.ltr ? TextAlign.left : TextAlign.right,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.2),
                  cursorRadius: const Radius.circular(2),
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hint,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textFaint,
                      height: 1.2,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    prefixIcon: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 16, end: 10),
                      child: AnimatedScale(
                        scale: _focused ? 1.08 : 1,
                        duration: const Duration(milliseconds: 240),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: hasError
                              ? AppColors.danger
                              : (_focused ? AppColors.purpleLight : colors.textMuted),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                    suffix: widget.maxLength != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              '${state.value?.length ?? widget.controller?.text.length ?? 0}/${widget.maxLength}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textFaint,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    suffixIcon: widget.suffixIcon ?? (widget.obscure
                        ? IconButton(
                            onPressed: () => setState(() => _hidden = !_hidden),
                            splashRadius: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            constraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            icon: Icon(
                              _hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: colors.textMuted,
                            ),
                          )
                        : null),
                  ),
                ),
              ),
            ),
            if (errorString != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
                child: Text(
                  errorString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (widget.helperText != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
                child: Text(
                  widget.helperText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
