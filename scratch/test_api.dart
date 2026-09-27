import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse('https://api.canadev.my.id/api/v1/reports?limit=5'));
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    print('STATUS: ${resp.statusCode}');
    final json = jsonDecode(body);
    if (json is Map && json['data'] is List) {
      for (final r in json['data']) {
        print('ID: ${r['id']} | Code: ${r['report_code']} | Cat: ${r['category']?['name']}');
        print('  urgency: ${r['urgency_score']} | damage_sev: ${r['damage_severity']} | manual_rev: ${r['needs_manual_review']}');
        print('  agency: ${r['assigned_agency']?['name']} | history: ${r['status_history']?.map((h) => h['note']).toList()}');
      }
    } else {
      print('RESPONSE: $json');
    }
  } catch (e) {
    print('ERROR: $e');
  } finally {
    client.close();
  }
}
