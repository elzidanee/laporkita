import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  // 1. Try to login with common credentials or check if there is an existing user
  // Let's test POST /api/v1/auth/login
  final req = await client.postUrl(Uri.parse('https://api.canadev.my.id/api/v1/auth/login'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({
    'identifier': 'operator@laporkita.id',
    'password': 'password123',
  }));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  print('LOGIN ATTEMPT 1: ${res.statusCode} -> $body');
}
