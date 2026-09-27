import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('https://api.canadev.my.id/api/v1/reports?limit=5'));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final json = jsonDecode(body);
  final data = json['data'] as List;
  for (var r in data) {
    print('--- REPORT ${r['report_code']} ---');
    print('photo_url: ${r['photo_url']}');
    print('media: ${r['media']}');
    print('category: ${r['category']}');
  }
  exit(0);
}
