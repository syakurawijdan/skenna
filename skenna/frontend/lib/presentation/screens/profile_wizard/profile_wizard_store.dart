class ProfileWizardDraft {
  String fullName = '';
  String gender = '';
  DateTime? birthDate;

  // Hypertension flow
  bool? hasHypertension;
  String? hypertensionCondition; // "history_only", "controlled", "uncontrolled"
  int? systolicPressure;
  int? diastolicPressure;

  // Pregnancy flow (only for perempuan)
  String? pregnancyStatus; // "pregnant", "breastfeeding", "none"
}

enum ProfileWizardStep {
  name,
  gender,
  birthDate,
  hypertensionStatus,
  hypertensionCondition,
  bloodPressure,
  pregnancy,
}

class ProfileWizardStore {
  ProfileWizardStore._();

  static final ProfileWizardStore instance = ProfileWizardStore._();
  final ProfileWizardDraft draft = ProfileWizardDraft();

  double progressForStep(ProfileWizardStep step) {
    final total = _totalSteps();
    final current = _stepIndex(step);
    final clampedCurrent = current.clamp(1, total);
    return clampedCurrent / total;
  }

  int _stepIndex(ProfileWizardStep step) {
    final hasHypertension = draft.hasHypertension;
    switch (step) {
      case ProfileWizardStep.name:
        return 1;
      case ProfileWizardStep.gender:
        return 2;
      case ProfileWizardStep.birthDate:
        return 3;
      case ProfileWizardStep.hypertensionStatus:
        return 4;
      case ProfileWizardStep.hypertensionCondition:
        return 5;
      case ProfileWizardStep.bloodPressure:
        return 6;
      case ProfileWizardStep.pregnancy:
        if (hasHypertension == false) {
          return 5;
        }
        return 7;
    }
  }

  int _totalSteps() {
    final gender = draft.gender.trim().toLowerCase();
    final isMale =
        gender == 'laki-laki' || gender == 'laki_laki' || gender == 'male';
    final isFemale = gender == 'perempuan' || gender == 'female';
    final hasHypertension = draft.hasHypertension;
    final birthDate = draft.birthDate;

    if (birthDate != null && _calculateAge(birthDate) < 18) {
      return 3;
    }

    if (isMale) {
      if (hasHypertension == false) {
        return 4;
      }
      if (hasHypertension == true) {
        return 6;
      }
    }

    if (isFemale) {
      if (hasHypertension == false) {
        return 5;
      }
      if (hasHypertension == true) {
        return 7;
      }
    }

    return 7;
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    final hasNotHadBirthdayThisYear =
        today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day);
    if (hasNotHadBirthdayThisYear) {
      age -= 1;
    }
    return age;
  }
}
