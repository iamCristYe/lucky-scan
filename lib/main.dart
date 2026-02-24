import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/group_selection_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/history_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // await prefs.clear(); // Persistence enabled
  runApp(const LuckyScanApp());
}

class LuckyScanApp extends StatelessWidget {
  const LuckyScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky Scan',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const DisclaimerScreen(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  String? _userId;
  String? _artistEvent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('x-user-id');
      _artistEvent = prefs.getString('x-artist-event');
      _isLoading = false;
    });
  }

  Future<void> _saveSession(String userId, String artistEvent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('x-user-id', userId);
    await prefs.setString('x-artist-event', artistEvent);
    setState(() {
      _userId = userId;
      _artistEvent = artistEvent;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _userId = null;
      _artistEvent = null;
    });
  }

  Future<void> _addToHistory(List<String> serials) async {
    if (_userId == null || _artistEvent == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'history_${_userId}_${_artistEvent}';
    
    List<String> history = prefs.getStringList(key) ?? [];
    history.addAll(serials);
    await prefs.setStringList(key, history);
  }

  void _handleScanComplete(List<String> serials) async {
    if (_userId == null || _artistEvent == null) return;

    final api = ApiService(userId: _userId!, artistEvent: _artistEvent!);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await api.registerSerialsBatch(serials);
      await _addToHistory(serials);
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully registered ${serials.length} codes!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userId == null || _artistEvent == null) {
      return GroupSelectionScreen(onLoginSuccess: _saveSession);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_artistEvent ?? 'Lucky Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => HistoryScreen(
                     userId: _userId!,
                     artistEvent: _artistEvent!,
                   ),
                 ),
               );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: ScannerScreen(onScanComplete: _handleScanComplete),
    );
  }
}
