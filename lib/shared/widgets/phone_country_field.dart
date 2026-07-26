// lib/shared/widgets/phone_country_field.dart
// Composant unique de saisie téléphone avec indicatif pays — vrais drapeaux
// (package country_code_picker), réutilisé à l'inscription/connexion, à la
// prise en charge, et dans l'interface intervenant "ajouter mon numéro".
// Ne jamais redupliquer ce widget.

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class PhoneCountryField extends StatelessWidget {
  final TextEditingController phoneController;
  final String initialCountryCode;
  final ValueChanged<String> onDialCodeChanged;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onPhoneChanged;

  const PhoneCountryField({
    super.key,
    required this.phoneController,
    required this.onDialCodeChanged,
    this.initialCountryCode = 'CI',
    this.hintText = '07 12 34 56 78',
    this.autofocus = false,
    this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CountryCodePicker(
          onChanged: (country) =>
              onDialCodeChanged(country.dialCode ?? '+225'),
          initialSelection: initialCountryCode,
          favorite: const ['+225', 'CI'],
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
          padding: EdgeInsets.zero,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CliinAppColors.textDark,
          ),
        ),
        Container(width: 1, height: 40, color: CliinAppColors.divider),
        Expanded(
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            autofocus: autofocus,
            onChanged: onPhoneChanged,
            style: GoogleFonts.inter(fontSize: 16, color: CliinAppColors.textDark),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle:
                  GoogleFonts.inter(fontSize: 16, color: CliinAppColors.textSecondary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
