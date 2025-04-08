import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/utill/styles.dart';

/// A reusable widget for phone number input with country code picker
class PhoneInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? countryCode;
  final Function(CountryCode)? onCountryChanged;
  final bool isDarkMode;
  final bool showSecurityBadge;

  const PhoneInputWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.countryCode,
    this.onCountryChanged,
    required this.isDarkMode,
    this.showSecurityBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and security badge
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Número de teléfono',
                  style: rubikMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            if (showSecurityBadge) _buildSecurityBadge(context),
          ],
        ),
        
        // Phone input container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDarkMode
                ? Colors.grey[900]
                : Colors.grey[50],
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Country code picker
              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: CountryCodePicker(
                  onChanged: onCountryChanged,
                  initialSelection: countryCode?.replaceAll('+', '') ?? 'US',
                  showDropDownButton: true,
                  padding: EdgeInsets.zero,
                  showFlagMain: true,
                  dialogBackgroundColor: Theme.of(context).cardColor,
                  flagWidth: 22,
                  textStyle: rubikRegular.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              
              // Phone number input field
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: rubikRegular.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 15,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    hintText: '123 456 7890',
                    hintStyle: rubikRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user,
            color: Colors.green,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            '100% Seguro',
            style: rubikMedium.copyWith(
              color: Colors.green,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
} 