import 'package:flutter/material.dart';

import '../app_shell.dart';

class SodiumLimitUnsafeScreen extends StatelessWidget {
  const SodiumLimitUnsafeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batas Natrium Tidak Aman')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 72,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Status Anda melebihi batas natrium aman.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kurangi asupan makanan tinggi natrium dan pantau rutin setiap hari.',
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
