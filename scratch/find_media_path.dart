import 'dart:io';

void main() async {
  final filename = '1790509295462-f9f6bfca-a732-4a8a-a032-5a97ca3e3bd0.jpg';
  final paths = [
    'https://api.canadev.my.id/reports/$filename',
    'https://api.canadev.my.id/api/v1/reports/media/$filename',
    'https://api.canadev.my.id/api/v1/media/$filename',
    'https://api.canadev.my.id/api/v1/uploads/$filename',
    'https://api.canadev.my.id/uploads/$filename',
    'https://api.canadev.my.id/storage/$filename',
    'https://api.canadev.my.id/public/$filename',
    'https://api.canadev.my.id/static/$filename',
    'https://canadev.my.id/reports/$filename',
    'https://storage.canadev.my.id/reports/$filename',
    'https://minio.canadev.my.id/reports/$filename',
  ];

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 3);

  for (final p in paths) {
    try {
      final req = await client.headUrl(Uri.parse(p));
      final res = await req.close();
      print('$p -> Status ${res.statusCode}');
    } catch (e) {
      print('$p -> Error $e');
    }
  }
}
