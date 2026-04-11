import 'package:flutter/material.dart';

import '../../data/api_client.dart';

enum HistoryRange { day, week, month }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = false;
  List<dynamic> _items = <dynamic>[];
  HistoryRange _selectedRange = HistoryRange.day;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final data = await widget.apiClient.getIntakeHistory(1);
      setState(() => _items = data);
    } catch (e) {
      setState(() => _items = <dynamic>['Gagal mengambil data: $e']);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, String>> get _displayItems {
    final mapped = _items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => <String, String>{
            'title': (item['food_name']?.toString().trim().isNotEmpty ?? false)
                ? item['food_name'].toString()
                : 'Monde Snack',
            'subtitle': '${item['sodium_mg'] ?? 1900} Mg/Na',
          },
        )
        .toList();

    if (mapped.isNotEmpty) {
      return mapped;
    }

    return List<Map<String, String>>.generate(
      4,
      (_) => <String, String>{'title': 'Monde Snack', 'subtitle': '1900 Mg/Na'},
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F5F7);
    const normalBlue = Color(0xFF2C4A8A);
    const lightText = Color(0xFFB0B0B0);

    return Container(
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 44),
            const Text(
              'Riwayat Scan',
              style: TextStyle(
                color: normalBlue,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _HistoryRangeSwitcher(
              selected: _selectedRange,
              onChanged: (range) {
                setState(() => _selectedRange = range);
              },
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                itemCount: _displayItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = _displayItems[i];
                  return Container(
                    padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '-',
                                style: const TextStyle(
                                  color: normalBlue,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w400,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] ?? '-',
                                style: const TextStyle(
                                  color: lightText,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w400,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: normalBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRangeSwitcher extends StatelessWidget {
  const _HistoryRangeSwitcher({
    required this.selected,
    required this.onChanged,
  });

  final HistoryRange selected;
  final ValueChanged<HistoryRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 282,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _RangePill(
            label: 'Hari Ini',
            isActive: selected == HistoryRange.day,
            onTap: () => onChanged(HistoryRange.day),
          ),
          const SizedBox(width: 12),
          _RangePill(
            label: 'Minggu',
            isActive: selected == HistoryRange.week,
            onTap: () => onChanged(HistoryRange.week),
          ),
          const SizedBox(width: 12),
          _RangePill(
            label: 'Bulan',
            isActive: selected == HistoryRange.month,
            onTap: () => onChanged(HistoryRange.month),
          ),
        ],
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const normalBlue = Color(0xFF2C4A8A);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? normalBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : normalBlue,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
