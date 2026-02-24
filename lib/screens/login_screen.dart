import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginScreen extends StatefulWidget {
  final Function(String userId, String artistEvent) onLoginSuccess;
  final String initialUrl;

  const LoginScreen({
    super.key, 
    required this.onLoginSuccess,
    required this.initialUrl,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _capturedEventId;
  String? _capturedArtistName;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LoginChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleLoginResponse(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _injectInterceptor();
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _injectInterceptor();
          },
        ),
      );
    
    // Clear all WebView data
    _controller.clearCache();
    _controller.clearLocalStorage();
    WebViewCookieManager().clearCookies();
    
    _controller.loadRequest(Uri.parse(widget.initialUrl));

  }

  void _injectInterceptor() {
    const String jsCode = '''
      (function() {
        if (window.isInterceptorInjected) return;
        window.isInterceptorInjected = true;

        // Hook XMLHttpRequest
        var oldOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url) {
            this._url = url;
            return oldOpen.apply(this, arguments);
        };

        var oldSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.send = function(body) {
            this.addEventListener('load', function() {
                if (this._url && (this._url.includes('external-api.fortunemeets.app/api/login/') || this._url.includes('config.json'))) {
                     try {
                         LoginChannel.postMessage(this.responseText);
                     } catch(e) {}
                }
            });
            return oldSend.apply(this, arguments);
        };

        // Hook fetch
        var oldFetch = window.fetch;
        window.fetch = function(input, init) {
            return oldFetch.apply(this, arguments).then(function(response) {
                if (input && (input.toString().includes('external-api.fortunemeets.app/api/login/') || input.toString().includes('config.json'))) {
                    response.clone().text().then(function(text) {
                         try {
                             LoginChannel.postMessage(text);
                         } catch(e) {}
                    });
                }
                return response;
            });
        };
      })();
    ''';
    _controller.runJavaScript(jsCode);
  }

  Future<void> _handleLoginResponse(String responseBody) async {
    try {
      final Map<String, dynamic> json = jsonDecode(responseBody);

      // Check for config.json response
      if (json.containsKey('eventId') && json.containsKey('artistName')) {
        _capturedEventId = json['eventId'];
        _capturedArtistName = json['artistName'];
        debugPrint("Captured config: $_capturedEventId - $_capturedArtistName");
        return;
      }

      // The user specified that "key" is the one used as x-user-id
      final String? key = json['key'];
      
      if (key != null && key.isNotEmpty) {
        // Derive x-artist-event from current URL or use captured one
        final String? currentUrl = await _controller.currentUrl();
        String artistEvent = "";
        
        if (_capturedEventId != null && _capturedEventId!.isNotEmpty) {
          artistEvent = _capturedEventId!;
        } else if (currentUrl != null) {
          final uri = Uri.parse(currentUrl);
          if (uri.pathSegments.isNotEmpty) {
             artistEvent = uri.pathSegments.last;
             if (uri.pathSegments.length >= 2) {
               artistEvent = "${uri.pathSegments[uri.pathSegments.length-2]}_${uri.pathSegments.last}";
             }
          }
        }
        
        if (mounted) {
           _showConfirmationDialog(key, artistEvent);
        }
      }
    } catch (e) {
      debugPrint("Error parsing login response: $e");
    }
  }

  void _showConfirmationDialog(String userId, String artistEvent) {
    // Avoid showing multiple dialogs
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session Captured"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Login detected!"),
            const SizedBox(height: 10),
            Text("User ID (key): $userId", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Artist Event: $artistEvent", style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_capturedArtistName != null) ...[
              const SizedBox(height: 5),
              Text("Artist Name: $_capturedArtistName"),
            ],
            const SizedBox(height: 10),
            const Text("This session will be used to register serial codes."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLoginSuccess(userId, artistEvent);
            },
            child: const Text("Confirm & Proceed"),
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
    );
  }
}
