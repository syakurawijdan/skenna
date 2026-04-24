class ProfileWizardDraft {
  String fullName = '';
  String gender = '';
  DateTime? birthDate;
  double? heightCm;
  double? weightKg;
  double? bmi;
  bool? hasHypertension;
  int? systolicPressure;
  int? diastolicPressure;
  bool? isPregnant;
}

class ProfileWizardStore {
  ProfileWizardStore._();

  static final ProfileWizardStore instance = ProfileWizardStore._();
  final ProfileWizardDraft draft = ProfileWizardDraft();
}
