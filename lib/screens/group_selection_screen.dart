import 'package:flutter/material.dart';
import 'login_screen.dart';

class GroupSelectionScreen extends StatelessWidget {
  const GroupSelectionScreen({super.key, required this.onLoginSuccess});

  final Function(String, String) onLoginSuccess;

  void _navigateToLogin(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          initialUrl: url,
          onLoginSuccess: (userId, artistEvent) {
            // Pop back to main wrapper so it can rebuild with new state
            Navigator.pop(context); 
            onLoginSuccess(userId, artistEvent);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Group')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToLogin(
                context, 
                'https://ticket.fortunemeets.app/nogizaka46/'
              ),
              child: const Text('Nogizaka46'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToLogin(
                context, 
                'https://ticket.fortunemeets.app/sakurazaka46/'
              ),
              child: const Text('Sakurazaka46'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToLogin(
                context, 
                'https://ticket.fortunemeets.app/hinatazaka46/'
              ),
              child: const Text('Hinatazaka46'),
            ),
          ],
        ),
      ),
    );
  }
}
