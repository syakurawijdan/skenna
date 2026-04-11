import 'package:flutter/material.dart';

import '../app_shell.dart';

class SodiumLimitSafeScreen extends StatelessWidget {
  const SodiumLimitSafeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batas Natrium Aman')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.verified_user, size: 72, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                'Status Anda saat ini dalam batas aman.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pertahankan konsumsi natrium harian sesuai rekomendasi.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const AppShell()),
                    (route) => false,
                  );
                },
                child: const Text('Mulai ke Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
