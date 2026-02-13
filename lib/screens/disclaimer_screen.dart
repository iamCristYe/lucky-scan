import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // Import MainWrapper

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _isAccepted = false;

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://x.com/itsunogi46');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
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
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Disclaimer: This application is an independent tool and is not affiliated with, endorsed by, or officially connected to Fortune Meets, Fortune Music, or any of their subsidiaries or partners. All trademarks and related intellectual property remain the property of their respective owners. By using this app, you acknowledge and agree that the developers and operators of the app assume no responsibility or liability for any errors, inaccuracies, data loss, financial loss, or other damages that may arise from the use of the app or reliance on the information provided within it. Use of this app is at your own risk.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _isAccepted,
                onChanged: (bool? value) {
                  setState(() {
                    _isAccepted = value ?? false;
                  });
                },
                title: const Text('I agree to the terms above'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isAccepted ? _navigateToMain : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continue',
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
