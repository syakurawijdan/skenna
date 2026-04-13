import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class Onboarding3Screen extends StatelessWidget {
  const Onboarding3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Onboarding 3',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chatbot akan membantu Anda memahami risiko dan rekomendasi konsumsi natrium.',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.profileForm);
                  },
                  child: const Text('Lanjutkan ke Isi Data Diri'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
