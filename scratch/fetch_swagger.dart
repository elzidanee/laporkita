import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse('https://api.canadev.my.id/api/docs-json'));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Swagger json length: ${body.length}');
    final swagger = jsonDecode(body);
    final paths = (swagger['paths'] as Map<String, dynamic>).keys.toList();
    print('Paths: $paths');
  } catch (e) {
    print('Error fetching swagger: $e');
  }
}
