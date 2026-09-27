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
        print('--- REPORT: ${r['id']} | ${r['report_code']} ---');
        print('photo_url: ${r['photo_url']}');
        print('media: ${r['media']}');
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
