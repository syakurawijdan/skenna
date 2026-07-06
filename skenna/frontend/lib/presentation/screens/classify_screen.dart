import 'package:flutter/material.dart';

import '../../data/api_client.dart';

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  final _controller = TextEditingController();
  String _result = 'Belum ada hasil';
  bool _loading = false;

  double? _parseIndoDouble(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  int? _parseIndoInt(String? text) {
    final parsed = _parseIndoDouble(text);
    return parsed?.toInt();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _parseIndoDouble(_controller.text.trim());
    if (value == null) {
      setState(() => _result = 'Input harus angka (mg).');
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await widget.apiClient.classifySodium(value);
      setState(() {
        _result =
            'Level: ${data['sodium_level']}\nRekomendasi: ${data['recommendation']}';
      });
    } catch (e) {
      setState(() => _result = 'Gagal klasifikasi: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Klasifikasi Natrium',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Natrium (mg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Memproses...' : 'Klasifikasikan'),
          ),
          const SizedBox(height: 16),
          Text(_result),
        ],
        ),
      ),
    );
  }
}
