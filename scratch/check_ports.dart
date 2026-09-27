import 'dart:io';

void main() async {
  final ports = [80, 443, 3000, 8000, 9000, 9001];
  for (final port in ports) {
    try {
      final s = await Socket.connect('api.canadev.my.id', port, timeout: const Duration(seconds: 2));
      print('api.canadev.my.id:$port -> OPEN');
      s.destroy();
    } catch (_) {
      print('api.canadev.my.id:$port -> CLOSED');
    }
  }

  for (final port in ports) {
    try {
      final s = await Socket.connect('canadev.my.id', port, timeout: const Duration(seconds: 2));
      print('canadev.my.id:$port -> OPEN');
      s.destroy();
    } catch (_) {
      print('canadev.my.id:$port -> CLOSED');
    }
  }
}
