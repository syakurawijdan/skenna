import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class SodiumLimitChoiceScreen extends StatelessWidget {
  const SodiumLimitChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batas Natrium Anda')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pilih skenario tampilan hasil batas natrium yang ingin ditampilkan.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.sodiumSafe);
                },
                child: const Text('Tampilkan Batas Aman'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.sodiumUnsafe);
                },
                child: const Text('Tampilkan Batas Tidak Aman'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
