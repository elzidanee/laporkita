import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('https://api.canadev.my.id/api/docs-json'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final swagger = jsonDecode(body);
  print(jsonEncode(swagger['paths']['/api/v1/reports/{id}/media']));
}
