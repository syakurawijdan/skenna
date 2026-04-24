import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/api_client.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_wizard/profile_wizard_store.dart';
import 'screens/scan_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final ApiClient _apiClient = ApiClient();

  DashboardGender _resolveDashboardGender(String rawGender) {
    final normalized = rawGender.trim().toLowerCase();
    if (normalized == 'female' ||
        normalized == 'perempuan' ||
        normalized == 'wanita') {
      return DashboardGender.female;
    }
    return DashboardGender.male;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ProfileWizardStore.instance.draft;
    final trimmedName = draft.fullName.trim();

    final screens = <Widget>[
      DashboardScreen(
        apiClient: _apiClient,
        userName: trimmedName.isEmpty ? null : trimmedName,
        gender: _resolveDashboardGender(draft.gender),
      ),
      ScanScreen(apiClient: _apiClient),
      HistoryScreen(apiClient: _apiClient),
    ];

    const navy = Color(0xFF2E4D93);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          IndexedStack(index: _index, children: screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 33 + MediaQuery.of(context).padding.bottom,
            child: Center(
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavButton(
                      active: _index == 0,
                      iconAsset: 'assets/icons/home.svg',
                      label: 'Beranda',
                      onTap: () => setState(() => _index = 0),
                    ),
                    const SizedBox(width: 12),
                    _NavButton(
                      active: _index == 1,
                      iconAsset: 'assets/icons/scan.svg',
                      label: 'Scan',
                      onTap: () => setState(() => _index = 1),
                    ),
                    const SizedBox(width: 12),
                    _NavButton(
                      active: _index == 2,
                      iconAsset: 'assets/icons/receipt-search.svg',
                      label: 'Riwayat',
                      onTap: () => setState(() => _index = 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.active,
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF2E4D93);

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: active ? 13 : 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(iconAsset, width: 19, height: 19),
            if (active) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
