import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginScreen extends StatefulWidget {
  final Function(String userId, String artistEvent) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ticket.fortunemeets.app/'));
  }

  Future<void> _captureSession() async {
    // 1. Try to get x-user-id from localStorage or cookies
    // Note: HttpOnly cookies cannot be accessed via JS.
    // However, the Python script uses `x-user-id` header which implies it might be stored 
    // in localStorage OR it is a visible cookie.
    
    // Let's try to extract from localStorage first as it's common for SPAs.
    final String? userId = await _runJavaScriptReturningString(
      "window.localStorage.getItem('userId') || window.localStorage.getItem('x-user-id') || document.cookie.match(/x-user-id=([^;]+)/)?.[1] || ''"
    );

    // 2. Derive x-artist-event from current URL
    final String? currentUrl = await _controller.currentUrl();
    String artistEvent = "";
    if (currentUrl != null) {
      final uri = Uri.parse(currentUrl);
      if (uri.pathSegments.isNotEmpty) {
        // e.g. https://ticket.fortunemeets.app/nogizaka46/5thAL
        // pathSegments: ['nogizaka46', '5thAL']
        // The header in python script example is "nogizaka46_39th" 
        // which looks like it might be a combination or a specific ID.
        // For now, let's default to the last segment or a specialized prompt.
        // Actually, the user might need to input this manually if it's not obvious.
        // We will default to the last segment but allow editing in a dialog.
        artistEvent = uri.pathSegments.last; 
        
        // If there are 2 segments, maybe join them?
        // Let's try to be smart: if 2 segments, join with underscore?
        if (uri.pathSegments.length >= 2) {
             artistEvent = "${uri.pathSegments[uri.pathSegments.length-2]}_${uri.pathSegments.last}";
        }
      }
    }
    
    if (userId != null && userId.isNotEmpty && userId != 'null' && userId != '""') {
       // Clean up quotes if returned by JS
       final cleanUserId = userId.replaceAll('"', '');
       _showConfirmationDialog(cleanUserId, artistEvent);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find user ID. Please login first.')),
      );
    }
  }
  
  Future<String> _runJavaScriptReturningString(String js) async {
      try {
          final result = await _controller.runJavaScriptReturningResult(js);
          return result.toString();
      } catch (e) {
          return "";
      }
  }

  void _showConfirmationDialog(String userId, String initialArtistEvent) {
    final TextEditingController eventController = TextEditingController(text: initialArtistEvent);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Session Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("User ID: $userId"),
            const SizedBox(height: 10),
            TextField(
              controller: eventController,
              decoration: const InputDecoration(labelText: "Artist Event (x-artist-event)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLoginSuccess(userId, eventController.text);
            },
            child: const Text("Save & Continue"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login to Fortune Meets")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _captureSession,
        label: const Text("Capture Session"),
        icon: const Icon(Icons.vpn_key),
      ),
    );
  }
}
