import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  final String artistEvent;

  const HistoryScreen({
    super.key,
    required this.userId,
    required this.artistEvent,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'history_${widget.userId}_${widget.artistEvent}';
    setState(() {
      _history = prefs.getStringList(key) ?? [];
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to clear the history for this session?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Clear")),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'history_${widget.userId}_${widget.artistEvent}';
      await prefs.remove(key);
      _loadHistory();
    }
  }

  void _copyToClipboard() {
    if (_history.isEmpty) return;
    final text = _history.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy All',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No history found for this session.'))
              : ListView.separated(
                  itemCount: _history.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final reverseIndex = _history.length - 1 - index;
                    return ListTile(
                      title: Text(_history[reverseIndex]),
                      leading: Text('#${reverseIndex + 1}'),
                    );
                  },
                ),
    );
  }
}
