import 'package:flutter/material.dart';
import '../../theme.dart';

class AppFormControls {
  static InputDecoration inputDecoration({
    required BuildContext context,
    String? labelText,
    String? hintText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.debtRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.debtRed, width: 1.5),
      ),
    );
  }
}

class AppPillOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const AppPillOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class AppPillGroup<T> extends StatelessWidget {
  final T selectedValue;
  final List<AppPillOption<T>> options;
  final ValueChanged<T> onSelected;

  const AppPillGroup({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: options.map((opt) {
        final isSelected = opt.value == selectedValue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(opt.value),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: opt.subtitle != null ? 8 : 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12)
                        : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opt.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                        ),
                      ),
                      if (opt.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          opt.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AppDropdownPill<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppDropdownPill({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class AppLiveValuationCard extends StatelessWidget {
  final String label;
  final String value;
  final String? secondaryText;

  const AppLiveValuationCard({
    super.key,
    required this.label,
    required this.value,
    this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (secondaryText != null) ...[
                const SizedBox(height: 2),
                Text(
                  secondaryText!,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
