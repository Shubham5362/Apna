import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFocusChange;
  final Widget? suffixWidget;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFocusChange,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (onFocusChange != null) onFocusChange!();
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            const Icon(
              Icons.smartphone_rounded,
              color: AppColors.subtextColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              '+91',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            Container(
              height: 20,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.borderGrey,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
                decoration: const InputDecoration(
                  hintText: 'Mobile Number',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (suffixWidget != null) ...[
              suffixWidget!,
              const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}
