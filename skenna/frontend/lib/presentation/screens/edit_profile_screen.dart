import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_client.dart';
import '../../data/user_session.dart';
import '../../domain/natrium_classifier.dart';
import '../navigation/app_routes.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/profile_avatar_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _blue = Color(0xFF2C4A8A);
  static const _border = Color(0xFFCCD2DF);
  static const _fieldFill = Colors.white;
  static const _selectedFill = Color(0xFFE1E6EF);
  static const _required = Color(0xFFE53935);
  static const _genderItems = [
    DropdownItem(value: 'perempuan', label: 'Perempuan'),
    DropdownItem(value: 'laki-laki', label: 'Laki-laki'),
  ];

  final ApiClient _apiClient = ApiClient();
  final _nameController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  // SESUDAH (aman)
  final TextEditingController _dayCtrl = TextEditingController();
  final TextEditingController _monthCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();
  final FocusNode _dayFocus = FocusNode();
  final FocusNode _monthFocus = FocusNode();
  final FocusNode _yearFocus = FocusNode();
  final FocusNode _systolicFocus = FocusNode();
  final FocusNode _diastolicFocus = FocusNode();

  bool _loading = true;
  bool _saving = false;
  String? _gender;
  bool? _hasHypertension;
  String? _hypertensionCondition;
  String? _pregnancyStatus;
  int? _day;
  int? _month;
  int? _year;

  @override
  void initState() {
    super.initState();
    _dayCtrl.addListener(() => setState(() {}));
    _monthCtrl.addListener(() => setState(() {}));
    _yearCtrl.addListener(() => setState(() {}));
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _dayCtrl.dispose();
    _dayFocus.dispose();
    _monthCtrl.dispose();
    _monthFocus.dispose();
    _yearCtrl.dispose();
    _yearFocus.dispose();
    _systolicFocus.dispose();
    _diastolicFocus.dispose();
    super.dispose();
  }

  bool get _isFemale => _gender == 'perempuan';

  DateTime? get _selectedBirthDate {
    final d = int.tryParse(_dayCtrl.text.trim());
    final m = int.tryParse(_monthCtrl.text.trim());
    final y = int.tryParse(_yearCtrl.text.trim());
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  bool get _shouldShowPregnancyQuestion {
    if (!_isFemale) return false;
    final birthDate = _selectedBirthDate;
    if (birthDate == null) return false;

    // SKI 2023 defines wanita usia subur as ages 10-54 for anthropometry.
    final usia = hitungUsiaTahun(birthDate);
    return usia >= 10 && usia <= 54;
  }

  bool get _isAdult {
    final birthDate = _selectedBirthDate;
    if (birthDate == null) return false;
    return hitungUsiaTahun(birthDate) >= 18;
  }

  int get _maxDay {
    if (_year == null || _month == null) return 31;
    final nextMonth = _month == 12
        ? DateTime(_year! + 1, 1, 1)
        : DateTime(_year!, _month! + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  Future<void> _loadProfile() async {
    try {
      final userId = UserSession().getUserId();
      debugPrint('EditProfile load userId: $userId');
      if (userId <= 0) {
        _redirectToLogin();
        return;
      }
      await ApiClient.setCurrentUserId(userId);
      final profile = await _apiClient.getUserProfile(userId);
      final birthDate = DateTime.parse(profile['birth_date'] as String);
      if (!mounted) return;
      setState(() {
        _nameController.text = profile['full_name'] as String? ?? '';
        _gender = profile['gender'] as String?;
        _hasHypertension = profile['has_hypertension'] as bool? ?? false;
        _hypertensionCondition = profile['hypertension_condition'] as String?;
        _systolicController.text =
            (profile['systolic_pressure'] as num?)?.toString() ?? '';
        _diastolicController.text =
            (profile['diastolic_pressure'] as num?)?.toString() ?? '';
        _pregnancyStatus = _normalizeUiPregnancyStatus(
          profile['pregnancy_status'] as String?,
        );
        _day = birthDate.day;
        _month = birthDate.month;
        _year = birthDate.year;
        _dayCtrl.text = birthDate.day.toString().padLeft(2, '0');
        _monthCtrl.text = birthDate.month.toString().padLeft(2, '0');
        _yearCtrl.text = birthDate.year.toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Gagal memuat profil: $e');
    }
  }

  String? _normalizeUiPregnancyStatus(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'pregnant' || normalized == 'breastfeeding') {
      return 'pregnant';
    }
    if (normalized == 'none') return 'none';
    return null;
  }

  Future<void> _save() async {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      _showMessage('Nama panggilan wajib diisi');
      return;
    }
    if (_gender == null || _day == null || _month == null || _year == null) {
      _showMessage('Lengkapi jenis kelamin dan tanggal lahir');
      return;
    }
    final birthDate = _selectedBirthDate!;
    final isAdult = _isAdult;

    if (isAdult && _hasHypertension == null) {
      _showMessage('Pilih riwayat hipertensi');
      return;
    }
    if (isAdult && _hasHypertension == true && _hypertensionCondition == null) {
      _showMessage('Pilih kondisi hipertensi');
      return;
    }
    if (_shouldShowPregnancyQuestion && _pregnancyStatus == null) {
      _showMessage('Pilih kondisi hamil atau menyusui');
      return;
    }

    int? systolic;
    int? diastolic;
    if (isAdult && _hasHypertension == true) {
      final systolicText = _systolicController.text.trim();
      final diastolicText = _diastolicController.text.trim();

      // Jika user membiarkan kosong, kita anggap null (aman)
      // Jika user mengetik '0', kita juga bisa menganggapnya sebagai null/tidak diisi
      systolic = (systolicText.isEmpty || systolicText == '0')
          ? null
          : int.tryParse(systolicText);
      diastolic = (diastolicText.isEmpty || diastolicText == '0')
          ? null
          : int.tryParse(diastolicText);

      // Sekarang validasi rentang HANYA berjalan jika angka > 0
      if (systolic != null && (systolic < 50 || systolic > 300)) {
        _showMessage('Sistolik harus berada di rentang 50-300');
        return;
      }
      if (diastolic != null && (diastolic < 30 || diastolic > 200)) {
        _showMessage('Diastolik harus berada di rentang 30-200');
        return;
      }
    }

    final effectiveHasHypertension = isAdult ? _hasHypertension! : false;
    final effectiveHypertensionCondition = isAdult && effectiveHasHypertension
        ? _hypertensionCondition
        : null;
    final effectiveSystolic = isAdult && effectiveHasHypertension
        ? systolic
        : null;
    final effectiveDiastolic = isAdult && effectiveHasHypertension
        ? diastolic
        : null;
    final effectivePregnancyStatus = _isFemale
        ? (_shouldShowPregnancyQuestion ? _pregnancyStatus : 'tidak_hamil')
        : null;

    setState(() => _saving = true);
    try {
      final userId = UserSession().getUserId();
      debugPrint('EditProfile save userId: $userId');
      if (userId <= 0) {
        setState(() => _saving = false);
        _redirectToLogin();
        return;
      }
      await ApiClient.setCurrentUserId(userId);
      await klasifikasiNatriumDariDraft(
        birthDate: birthDate,
        gender: _gender!,
        hasHypertension: effectiveHasHypertension,
        hypertensionCondition: effectiveHypertensionCondition,
        systolicPressure: effectiveSystolic,
        diastolicPressure: effectiveDiastolic,
        pregnancyStatus: effectivePregnancyStatus,
      );
      await _apiClient.upsertUserProfile(
        userId: userId,
        fullName: fullName,
        gender: _gender!,
        birthDate: birthDate,
        hasHypertension: effectiveHasHypertension,
        hypertensionCondition: effectiveHypertensionCondition,
        systolicPressure: effectiveSystolic,
        diastolicPressure: effectiveDiastolic,
        pregnancyStatus: effectivePregnancyStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Gagal menyimpan profil: $e');
    }
  }

  int? _parseOptionalInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _redirectToLogin() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi pengguna belum ditemukan. Silakan masuk ulang.'),
      ),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding1);
  }

  // ── Dekorasi field teks biasa (nama, sistolik, diastolik) ──────────────────
  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: false,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  // ── Dekorasi field tanggal (onboarding style) ──────────────────────────────
  InputDecoration _dateInputDecoration(String hintText, {String? errorText}) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFB0B0B0),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _required),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _required),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        color: _required,
        fontSize: 9,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _dateTextField({
    required String label,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required String hint,
    required int maxLen,
    FocusNode? nextFocus,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: _blue,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          maxLength: maxLen,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) {
            final parsed = int.tryParse(v);
            setState(() {
              if (ctrl == _dayCtrl) _day = parsed;
              if (ctrl == _monthCtrl) _month = parsed;
              if (ctrl == _yearCtrl) _year = parsed;
            });
            if (v.length == maxLen && nextFocus != null) {
              nextFocus.requestFocus();
            }
          },
          style: GoogleFonts.plusJakartaSans(
            color: _blue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: _dateInputDecoration(hint, errorText: errorText).copyWith(
            counterText: '',
            constraints: const BoxConstraints(maxHeight: 52),
          ),
        ),
      ],
    );
  }

  Widget _bloodPressureTextField({
    required String label,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required String hint,
    FocusNode? nextFocus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF2C4A8A),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF2C4A8A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFB0B0B0),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCCD2DF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCCD2DF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2C4A8A)),
            ),
          ),
        ),
      ],
    );
  }

  String? _dayError() {
    final day = int.tryParse(_dayCtrl.text.trim());
    if (day == null || _dayCtrl.text.isEmpty) return null;
    if (day < 1 || day > 31) return 'Tanggal tidak valid';
    if (_month != null && day > _maxDay) return 'Maks. $_maxDay hari';
    return null;
  }

  String? _monthError() {
    final m = int.tryParse(_monthCtrl.text.trim());
    if (m == null || _monthCtrl.text.isEmpty) return null;
    if (m < 1 || m > 12) return 'Bulan tidak valid';
    return null;
  }

  // ── Label field ────────────────────────────────────────────────────────────
  Widget _label(String text, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: '*',
                style: TextStyle(color: _required),
              ),
          ],
        ),
        style: GoogleFonts.plusJakartaSans(
          color: _blue,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _radioOption({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFDFE4ED) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBEC7DB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _blue, width: 2),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        color: _blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      children: _boldFirstWord(label),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _boldFirstWord(String label) {
    final commaIndex = label.indexOf(',');
    if (commaIndex == -1) return [TextSpan(text: label)];
    return [
      TextSpan(
        text: label.substring(0, commaIndex + 1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextSpan(text: label.substring(commaIndex + 1)),
    ];
  }

  Widget _conditionButton(String value, String label) {
    final selected = _hypertensionCondition == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFDFE4ED) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _hypertensionCondition = value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBEC7DB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _blue, width: 2),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _selectedGenderLabel() {
    for (final item in _genderItems) {
      if (item.value == _gender) return item.label;
    }
    return null;
  }

  Widget _pregnancyOption({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFDFE4ED) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFBEC7DB),
                width: 1, // Pastikan lebar border sama
              ),
            ),
            child: Row(
              children: [
                // Indikator Radio
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2C4A8A),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2C4A8A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2C4A8A),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _isFemale
        ? 'assets/illustrations/avatar_cewe_pink.png'
        : 'assets/illustrations/avatar_cowo.png';
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = (size.width * 0.08).clamp(20.0, 33.0).toDouble();
    final sectionGap = (size.height * 0.035).clamp(24.0, 38.0).toDouble();
    final avatarSize = (size.height * 0.13).clamp(84.0, 108.0).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App bar ──────────────────────────────────────────────
                    Row(
                      children: [
                        Material(
                          color: const Color(0xFFDFE4ED),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.arrow_back,
                                color: _blue,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Edit Profile',
                              style: GoogleFonts.plusJakartaSans(
                                color: _blue,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 46),
                      ],
                    ),
                    SizedBox(height: sectionGap),

                    // ── Avatar ───────────────────────────────────────────────
                    Center(
                      child: SizedBox(
                        width: avatarSize,
                        height: avatarSize,
                        child: ProfileAvatarImage(
                          asset: avatar,
                          size: avatarSize,
                          debugLabel: 'Edit profile avatar',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    _label('Nama panggilan'),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.plusJakartaSans(
                        color: _blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _fieldDecoration(hint: 'Nama panggilan'),
                    ),
                    const SizedBox(height: 22),
                    _label('Jenis Kelamin'),
                    CustomDropdownField(
                      value: _selectedGenderLabel(),
                      placeholder: 'Pilih Jenis Kelamin',
                      textAlign: TextAlign.left,
                      height: 55,
                      fontSize: 15,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      onTap: () async {
                        final value = await showCustomDropdown<String>(
                          context: context,
                          title: 'Pilih Jenis Kelamin',
                          items: _genderItems,
                          selectedValue: _gender,
                        );
                        if (value == null) return;
                        setState(() {
                          _gender = value;
                          if (!_isFemale) _pregnancyStatus = null;
                        });
                      },
                    ),
                    const SizedBox(height: 22),

                    // ── Tanggal Lahir ─────────────────────────────────────────
                    _label('Tanggal lahir'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _dateTextField(
                            label: 'Hari',
                            ctrl: _dayCtrl,
                            focusNode: _dayFocus,
                            hint: 'DD',
                            maxLen: 2,
                            nextFocus: _monthFocus,
                            errorText: _dayError(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _dateTextField(
                            label: 'Bulan',
                            ctrl: _monthCtrl,
                            focusNode: _monthFocus,
                            hint: 'MM',
                            maxLen: 2,
                            nextFocus: _yearFocus,
                            errorText: _monthError(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _dateTextField(
                            label: 'Tahun',
                            ctrl: _yearCtrl,
                            focusNode: _yearFocus,
                            hint: 'YYYY',
                            maxLen: 4,
                          ),
                        ),
                      ],
                    ),

                    // ── Hipertensi (hanya dewasa) ─────────────────────────────
                    if (_isAdult) ...[
                      const SizedBox(height: 22),
                      _label('Riwayat Hipertensi'),
                      _radioOption(
                        selected: _hasHypertension == true,
                        label: 'Ya, saya pernah didiagnosis hipertensi',
                        onTap: () => setState(() {
                          _hasHypertension = true;
                          _hypertensionCondition ??= 'uncontrolled';
                        }),
                      ),
                      _radioOption(
                        selected: _hasHypertension == false,
                        label:
                            'Tidak, saya tidak pernah didiagnosis hipertensi',
                        onTap: () => setState(() {
                          _hasHypertension = false;
                          _hypertensionCondition = null;
                          _systolicController.clear();
                          _diastolicController.clear();
                        }),
                      ),
                      const SizedBox(height: 11),
                      if (_hasHypertension == true) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _bloodPressureTextField(
                                label: 'Sistolik',
                                ctrl: _systolicController,
                                focusNode: _systolicFocus,
                                hint: 'Isi sistolik',
                                nextFocus: _diastolicFocus,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _bloodPressureTextField(
                                label: 'Diastolik',
                                ctrl: _diastolicController,
                                focusNode: _diastolicFocus,
                                hint: 'Isi diastolik',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    // ── Kondisi hamil/menyusui (perempuan) ───────────────────
                    // ── Kondisi hamil/menyusui (perempuan) ───────────────────
                    if (_shouldShowPregnancyQuestion) ...[
                      const SizedBox(height: 22),
                      _label('Kondisi Hamil/Menyusui'),
                      _pregnancyOption(
                        selected: _pregnancyStatus == 'pregnant',
                        label: 'Hamil atau Menyusui',
                        onTap: () =>
                            setState(() => _pregnancyStatus = 'pregnant'),
                      ),
                      _pregnancyOption(
                        selected: _pregnancyStatus == 'none',
                        label: 'Tidak Keduanya',
                        onTap: () => setState(() => _pregnancyStatus = 'none'),
                      ),
                    ],

                    // Jarak statis yang aman antara form terakhir dengan tombol
                    const SizedBox(height: 40),

                    // ── Tombol Simpan Perubahan (Ikut ter-scroll & Bebas Overflow) ──
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 343),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2C4A8A),
                              disabledBackgroundColor: const Color(0xFFD9D9D9),
                              elevation: 4,
                              shadowColor: const Color(0x40000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Simpan Perubahan',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
