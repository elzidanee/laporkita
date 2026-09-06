import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/core/network/api_exception.dart';
import 'package:laporkita/core/network/dio_client.dart';

class MockAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options) handler;

  MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.remove(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioClient dioClient;
  late MockAdapter mockAdapter;
  late FakeSecureStorage fakeStorage;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (methodCall) async => null,
    );

    DioClient.resetInstance();
    fakeStorage = FakeSecureStorage();
    dioClient = DioClient(storage: fakeStorage);
    mockAdapter = MockAdapter((options) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"message":"ok"}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    dioClient.dio.httpClientAdapter = mockAdapter;
  });

  tearDown(() {
    DioClient.resetInstance();
  });

  group('DioClient P0-02 Defensive Response Handling Tests', () {
    test('A. HTML 502 Bad Gateway response does NOT throw TypeError, throws ApiException', () async {
      const html502 = '''
<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
<hr><center>nginx/1.18.0</center>
</body>
</html>
''';

      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          html502,
          502,
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
          },
        );
      };

      try {
        await dioClient.get<dynamic>('/test-502', fromJson: (json) => json);
        fail('Should throw ApiException');
      } on ApiException catch (e) {
        expect(e.code, equals('BAD_GATEWAY'));
        expect(e.statusCode, equals(502));
        expect(e.userMessage, contains('gangguan'));
        expect(e.userMessage.contains('<html'), isFalse);
      } catch (e) {
        fail('Unexpected exception type: ${e.runtimeType} -> $e');
      }
    });

    test('B. HTML 503 Service Unavailable response does NOT crash, throws controlled ApiException', () async {
      const html503 = '''
<!DOCTYPE html>
<html>
<head><title>503 Service Temporarily Unavailable</title></head>
<body>
<h1>503 Service Temporarily Unavailable</h1>
</body>
</html>
''';

      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          html503,
          503,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        );
      };

      try {
        await dioClient.get<dynamic>('/test-503', fromJson: (json) => json);
        fail('Should throw ApiException');
      } on ApiException catch (e) {
        expect(e.code, equals('SERVICE_UNAVAILABLE'));
        expect(e.statusCode, equals(503));
        expect(e.userMessage, contains('sedang dalam pemeliharaan'));
        expect(e.userMessage.contains('<h1>'), isFalse);
      } catch (e) {
        fail('Unexpected exception type: ${e.runtimeType} -> $e');
      }
    });

    test('C. HTML 504 Gateway Timeout response does NOT crash, throws controlled ApiException', () async {
      const html504 = '<html><body>504 Gateway Time-out</body></html>';

      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          html504,
          504,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        );
      };

      try {
        await dioClient.get<dynamic>('/test-504', fromJson: (json) => json);
        fail('Should throw ApiException');
      } on ApiException catch (e) {
        expect(e.code, equals('GATEWAY_TIMEOUT'));
        expect(e.statusCode, equals(504));
        expect(e.userMessage, contains('habis'));
      } catch (e) {
        fail('Unexpected exception type: ${e.runtimeType} -> $e');
      }
    });

    test('D. Malformed JSON string response does not crash with TypeError', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{ broken json string ...',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await dioClient.get<dynamic>('/test-malformed', fromJson: (json) => json);
        fail('Should throw ApiException or parsing error');
      } on ApiException catch (e) {
        expect(e.code, anyOf(equals('INVALID_RESPONSE_FORMAT'), equals('PARSING_ERROR')));
      } catch (e) {
        fail('Unexpected exception: ${e.runtimeType} -> $e');
      }
    });

    test('Empty / null response body does not cause TypeError crash', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          '',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await dioClient.get<dynamic>('/test-empty', fromJson: (json) => json);
        fail('Should throw ApiException');
      } on ApiException catch (e) {
        expect(e.code, anyOf(equals('EMPTY_RESPONSE'), equals('INVALID_RESPONSE_FORMAT')));
      } catch (e) {
        fail('Unexpected exception: ${e.runtimeType} -> $e');
      }
    });

    test('Standard valid JSON object succeeds and parses cleanly', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'id': '123', 'name': 'LaporKita'},
            'message': 'OK',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final response = await dioClient.get<Map<String, dynamic>>(
        '/test-valid',
        fromJson: (json) => Map<String, dynamic>.from(json as Map),
      );
      expect(response.success, isTrue);
      expect(response.data?['id'], equals('123'));
    });

    test('Standard valid JSON array succeeds and parses cleanly', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': [
              {'id': '1'},
              {'id': '2'}
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final response = await dioClient.get<List<dynamic>>(
        '/test-array',
        fromJson: (json) => List<dynamic>.from(json as List),
      );
      expect(response.success, isTrue);
      expect(response.data?.length, equals(2));
    });
  });
}
