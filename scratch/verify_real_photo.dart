import 'dart:io';

void main() async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('https://canadev.my.id/reports/1790509295462-f9f6bfca-a732-4a8a-a032-5a97ca3e3bd0.jpg'));
  final res = await req.close();
  print('Status: ${res.statusCode}');
  print('Content-Type: ${res.headers.contentType}');
  print('Content-Length: ${res.contentLength}');
}
