import 'dart:io';

void main() async {
  final filename = '1790509295462-f9f6bfca-a732-4a8a-a032-5a97ca3e3bd0.jpg';
  final paths = [
    'https://ai.canadev.my.id/reports/$filename',
    'https://ai.canadev.my.id/media/$filename',
    'https://ai.canadev.my.id/static/$filename',
  ];

  final client = HttpClient();
  for (final p in paths) {
    try {
      final req = await client.getUrl(Uri.parse(p));
      final res = await req.close();
      print('$p -> Status ${res.statusCode}');
    } catch (e) {
      print('$p -> Error $e');
    }
  }
}
