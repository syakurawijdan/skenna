import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_routes.dart';
import '../../widgets/custom_dropdown.dart';
import 'profile_step_layout.dart';
import 'profile_wizard_store.dart';

class ProfileGenderScreen extends StatefulWidget {
  const ProfileGenderScreen({super.key});

  @override
  State<ProfileGenderScreen> createState() => _ProfileGenderScreenState();
}

class _ProfileGenderScreenState extends State<ProfileGenderScreen> {
  String? _gender;
  late final String _displayName;

  @override
  void initState() {
    super.initState();
    final draft = ProfileWizardStore.instance.draft;
    _gender = draft.gender.isEmpty ? null : draft.gender;
    final trimmedName = draft.fullName.trim();
    _displayName = trimmedName.isEmpty ? 'Nama User' : trimmedName;
  }

  void _next() {
    if (_gender == null) {
      return;
    }
    final gender = _gender!;
    ProfileWizardStore.instance.draft.gender = gender;
    Navigator.pushNamed(context, AppRoutes.profileBirthDate);
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _gender != null;
    final progress = ProfileWizardStore.instance.progressForStep(
      ProfileWizardStep.gender,
    );
    final genderLabel = switch (_gender?.toLowerCase()) {
      'perempuan' => 'Perempuan',
      'laki-laki' => 'Laki-laki',
      _ => _gender,
    };

    return ProfileStepLayout(
      progress: progress,
      illustrationAsset: 'assets/illustrations/gender.png',
      title: 'Halo, $_displayName',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jenis Kelamin',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF2C4A8A),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          CustomDropdownField(
            value: genderLabel,
            placeholder: 'Pilih Jenis Kelamin',
            textAlign: TextAlign.left,
            height: 55,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            onTap: () async {
              final value = await showCustomDropdown<String>(
                context: context,
                title: 'Pilih Jenis Kelamin',
                items: const [
                  DropdownItem(value: 'Perempuan', label: 'Perempuan'),
                  DropdownItem(value: 'Laki-laki', label: 'Laki-laki'),
                ],
                selectedValue: genderLabel,
              );
              if (value == null) return;
              setState(() {
                _gender = value.toLowerCase();
              });
            },
          ),
        ],
      ),
      subtitle: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF2C4A8A),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
          children: const [
            TextSpan(text: 'Semakin '),
            TextSpan(
              text: 'lengkap data',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' yang kamu isi,\nsemakin '),
            TextSpan(
              text: 'akurat',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' hasil analisis dari'),
            TextSpan(
              text: ' Skenna',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      primaryButton: FilledButton(
        onPressed: isFormValid ? _next : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2C4A8A),
          disabledBackgroundColor: const Color(0xFFB0B0B0),
          elevation: 4,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Selanjutnya',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
