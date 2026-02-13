import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = "https://ticket-api.fortunemeets.app/serial/register";
  
  // Headers that are constant or managed
  static const Map<String, String> _baseHeaders = {
    "accept": "application/json, text/plain, */*",
    "accept-language": "en-GB,en;q=0.9,ja;q=0.8,zh-CN;q=0.7,zh;q=0.6",
    "cache-control": "no-cache",
    "content-type": "application/json",
    "dnt": "1",
    "origin": "https://ticket.fortunemeets.app",
    "pragma": "no-cache",
    "priority": "u=1, i",
    "referer": "https://ticket.fortunemeets.app/",
    "sec-ch-ua": '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": '"Android"',
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-site",
    // User agent should ideally match the WebView's or a standard Android one
    "user-agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36",
  };

  final String userId;
  final String artistEvent;

  ApiService({required this.userId, required this.artistEvent});

  Future<void> registerSerialsBatch(List<String> serials) async {
    final headers = {
      ..._baseHeaders,
      "x-artist-event": artistEvent,
      "x-user-id": userId,
    };

    final payload = jsonEncode({"serialList": serials});

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: payload,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("Batch $serials: Status ${response.statusCode}, Response: ${response.body}");
      } else {
        throw Exception("Failed to register batch. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error for batch $serials: $e");
      rethrow;
    }
  }
}
