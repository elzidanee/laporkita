import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  // Let's test calling PATCH /api/v1/reports/some-id/status without token
  final req = await client.patchUrl(Uri.parse('https://api.canadev.my.id/api/v1/reports/mock-1/status'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({'status': 'in_progress', 'note': 'test'}));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  print('NO TOKEN STATUS CODE: ${res.statusCode}');
  print('NO TOKEN RESPONSE: $body');
}
