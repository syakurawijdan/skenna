import 'package:flutter/material.dart';

import '../../data/api_client.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = TextEditingController(
    text: 'https://example.com/food-label.jpg',
  );
  String _result = 'Belum ada hasil scan';
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final imageUrl = _controller.text.trim();
    if (imageUrl.isEmpty) {
      setState(() => _result = 'Isi URL gambar dulu.');
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await widget.apiClient.scanLabel(imageUrl);
      setState(() {
        _result =
            'Sodium: ${data['sodium_mg']} mg\nLevel: ${data['sodium_level']}\n\nRaw OCR:\n${data['raw_text']}';
      });
    } catch (e) {
      setState(() => _result = 'Gagal scan: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Scan Label Makanan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'URL Gambar Label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _scan,
            child: Text(_loading ? 'Scanning...' : 'Scan Label'),
          ),
          const SizedBox(height: 16),
          Text(_result),
        ],
      ),
    );
  }
}
