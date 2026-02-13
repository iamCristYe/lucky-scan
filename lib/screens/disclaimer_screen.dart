import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // Import MainWrapper

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://x.com/itsunogi46');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 32),
              const Text(
                'Disclaimer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'This tool is created by たたん',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _launchUrl,
                child: const Text(
                  '(https://x.com/itsunogi46)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We will not be responsible for any error, data loss, money loss, etc.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainWrapper()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'I Understand & Continue',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
