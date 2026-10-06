import 'package:flutter_driver/driver_extension.dart';
import 'package:laporkita/main.dart' as app;

void main() {
  // Aktifkan Flutter Driver extension SEBELUM aplikasi dijalankan,
  // agar Appium Flutter Driver dapat berkomunikasi dengan widget tree via Dart VM.
  enableFlutterDriverExtension();
  app.main();
}
