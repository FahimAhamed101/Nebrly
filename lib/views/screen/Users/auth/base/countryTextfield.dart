import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../../utils/app_colors.dart';


class CustomCountryCodePicker extends StatelessWidget {
  final String initialCountryCode;
  final TextEditingController countryCodeController;
  final Function(String dialCode, String countryName)? onCountryChanged;

  const CustomCountryCodePicker({
    super.key,
    this.initialCountryCode = 'BD',
    required this.countryCodeController,
    this.onCountryChanged,
  });


  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      initialValue: initialCountryCode,
      showCursor: true,
      readOnly: false, // Prevents manual number input
      showDropdownIcon: true,
      dropdownTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        prefixIconConstraints: BoxConstraints(
          minWidth: 40, // or your desired width
          minHeight: 40, // or your desired height
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.Red,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            width: 1,
            color: AppColors.LightGray,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.DarkGray.withOpacity(0.60),
          ),
        ),
        hintText: "Enter phone",
        hintStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Theme.of(context).textTheme.titleSmall?.color,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 1, vertical: 15),
      ),
      initialCountryCode: initialCountryCode,
      onChanged: (phone) {
      countryCodeController.text = phone.completeNumber;
    },
      onCountryChanged: (country) {
        countryCodeController.text = country.dialCode;
        if (onCountryChanged != null) {
          onCountryChanged!(country.dialCode, country.name);
        }
      },
    );
  }
}