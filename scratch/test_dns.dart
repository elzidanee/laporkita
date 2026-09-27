import 'dart:io';

void main() async {
  final url = 'https://storage.laporkita.malangkota.go.id/reports/1790509295462-f9f6bfca-a732-4a8a-a032-5a97ca3e3bd0.jpg';
  try {
    print('Testing lookup for storage.laporkita.malangkota.go.id...');
    final ips = await InternetAddress.lookup('storage.laporkita.malangkota.go.id');
    print('IPs: $ips');
  } catch (e) {
    print('DNS lookup failed: $e');
  }

  // Also test api.canadev.my.id
  try {
    print('Testing lookup for api.canadev.my.id...');
    final ips = await InternetAddress.lookup('api.canadev.my.id');
    print('IPs: $ips');
  } catch (e) {
    print('DNS lookup failed: $e');
  }
}
