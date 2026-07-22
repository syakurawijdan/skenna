import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/api_client.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_wizard/profile_wizard_store.dart';
import 'screens/scan_screen.dart';
import 'widgets/navigation_overlay.dart';
import '../../../data/user_session.dart';
import 'navigation/app_routes.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0}); // ← tambahkan ini

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late int _index;
  final ApiClient _apiClient = ApiClient();
  final _historyScreenKey = GlobalKey<HistoryScreenState>();

  String? _userName;
  DashboardGender _gender = DashboardGender.male;
  bool _isLoading = true;
  int _dashboardRefreshToken = 0;
  late final NavigationOverlayController _navigationOverlayController;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _navigationOverlayController = NavigationOverlayController(vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _navigationOverlayController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userSession = UserSession();
      final userId = userSession.getUserId();
      debugPrint('=== userId: $userId');
      if (userId > 0) {
        final user = await _apiClient.getUserProfile(userId);
        debugPrint('=== profile response: $user'); // ← fetch dari API
        setState(() {
          _userName = user['full_name'] as String?;
          _gender = _resolveDashboardGender(user['gender'] as String? ?? '');
          _dashboardRefreshToken++;
        });
      }
    } on ApiException catch (e) {
      debugPrint('=== error: $e');
      if (e.statusCode == 401 && mounted) {
        await ApiClient.clearLocalSession();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi kamu telah berakhir, silakan login ulang.'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('=== error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
    const navBarWidth = 264.0;
    const navBarHeight = 68.0;
    const navItemSpacing = 6.0;
    final navBottom = 20 + MediaQuery.of(context).padding.bottom;
    final overlayBottom = navBottom + navBarHeight + 10;
    const navItemCenters = <NavigationOverlayType, double>{
      NavigationOverlayType.home: 32,
      NavigationOverlayType.scan: navBarWidth / 2,
      NavigationOverlayType.history: navBarWidth - 34,
      NavigationOverlayType.profile: navBarWidth - 34,
    };
    final screens = <Widget>[
      DashboardScreen(
        key: ValueKey(_dashboardRefreshToken),
        apiClient: _apiClient,
        userName: _userName,
        gender: _gender,
        refreshToken: _dashboardRefreshToken,
        onProfileUpdated: () {
          _loadUserProfile();
          setState(() => _dashboardRefreshToken++);
        },
      ),
      ScanScreen(apiClient: _apiClient),
      HistoryScreen(key: _historyScreenKey, apiClient: _apiClient),
    ];

    const navy = Color(0xFF2C4A8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          if (_index == 0) screens[0],
          if (_index == 1) screens[1],
          if (_index == 2) screens[2],
          // PERBAIKAN: Hanya tampilkan navbar jika sedang TIDAK di halaman Scan (_index != 1)
          if (_index != 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: navBottom,
              child: Center(
                child: Container(
                  width: navBarWidth,
                  height: navBarHeight,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x330F172A),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _NavItemSlot(
                        active: _index == 0,
                        child: _NavButton(
                          active: _index == 0,
                          iconAsset: 'assets/icons/home.svg',
                          label: 'Beranda',
                          onTap: () {
                            setState(() {
                              _index = 0;
                              _dashboardRefreshToken++;
                            });
                            _navigationOverlayController.dismiss();
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                if (!mounted) return;
                                _navigationOverlayController.showIfNeeded(
                                  context,
                                  NavigationOverlayType.home, // ✅
                                  navBarWidth: navBarWidth,
                                  navItemCenters: navItemCenters,
                                  bottom: overlayBottom,
                                  userId: UserSession().getUserId(),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: navItemSpacing),
                      _NavItemSlot(
                        active: _index == 1,
                        child: _NavButton(
                          active: _index == 1,
                          iconAsset: 'assets/icons/scan.svg',
                          label: 'Scan',
                          onTap: () {
                            setState(() => _index = 1);
                            _navigationOverlayController.dismiss();
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                if (!mounted) return;
                                _navigationOverlayController.showIfNeeded(
                                  context,
                                  NavigationOverlayType.scan, // ✅ bukan .home
                                  navBarWidth: navBarWidth,
                                  navItemCenters: navItemCenters,
                                  bottom: overlayBottom,
                                  userId: UserSession().getUserId(),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: navItemSpacing),
                      _NavItemSlot(
                        active: _index == 2,
                        child: _NavButton(
                          active: _index == 2,
                          iconAsset: 'assets/icons/receipt-search.svg',
                          label: 'Riwayat',
                          onTap: () {
                            setState(() => _index = 2);
                            _historyScreenKey.currentState?.refresh();
                            _navigationOverlayController.dismiss();
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                if (!mounted) return;
                                _navigationOverlayController.showIfNeeded(
                                  context,
                                  NavigationOverlayType
                                      .history, // ✅ bukan .home
                                  navBarWidth: navBarWidth,
                                  navItemCenters: navItemCenters,
                                  bottom: overlayBottom,
                                  userId: UserSession().getUserId(),
                                );
                              },
                            );
                          },
                        ),
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

class _NavItemSlot extends StatelessWidget {
  const _NavItemSlot({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Expanded(child: child);
    }

    return SizedBox(width: 48, child: child);
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
    const navy = Color(0xFF2C4A8A);

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        width: active ? double.infinity : 48,
        constraints: const BoxConstraints(minWidth: 48),
        padding: EdgeInsets.symmetric(horizontal: active ? 12 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: active ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconAsset, width: 20, height: 20),
            if (active) ...[
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
