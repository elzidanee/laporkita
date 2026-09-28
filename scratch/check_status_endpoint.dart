import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('https://api.canadev.my.id/api/docs-json'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final swagger = jsonDecode(body);
  print('KEYS: ${swagger['paths'].keys.where((k) => k.toString().contains('status')).toList()}');
  for (final k in swagger['paths'].keys) {
    if (k.toString().contains('status')) {
      print('$k: ${jsonEncode(swagger['paths'][k])}');
    }
  }
}
