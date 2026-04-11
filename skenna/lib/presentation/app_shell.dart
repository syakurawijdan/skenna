import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/api_client.dart';
import 'screens/chatbot_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final ApiClient _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(apiClient: _apiClient),
      ChatbotScreen(apiClient: _apiClient),
      HistoryScreen(apiClient: _apiClient),
    ];

    const navy = Color(0xFF2E4D93);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(65, 0, 65, 33),
        child: Row(
          children: [
            Expanded(
              child: Container(
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
                      label: 'Chat',
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
          ],
        ),
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
          horizontal: active ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(iconAsset, width: 22, height: 22),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
