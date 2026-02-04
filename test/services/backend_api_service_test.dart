import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:schoolable/services/backend_api_service.dart';

String buildTestToken({Duration validFor = const Duration(hours: 1)}) {
  final expiry = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(
    utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
  );
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'exp': expiry})),
  );
  return '$header.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.loadFromString(envString: 'BACKEND_URL=http://example.com');
  });

  test('signIn saves token and enables session', () async {
    final token = buildTestToken();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': token,
            'profile': {'id': 'user-1'},
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = BackendApiService(client: client);

    await api.signIn(email: 'user@schoolable.com', password: 'password123');

    expect(await api.hasSession(), isTrue);
    expect(await api.getCurrentToken(), token);
  });

  test('completeProfile adds Authorization header', () async {
    final token = buildTestToken();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': token,
            'profile': {'id': 'user-1'},
          }),
          200,
        );
      }
      if (request.url.path == '/profile/complete') {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response('{}', 200);
      }
      return http.Response('Not Found', 404);
    });

    final api = BackendApiService(client: client);

    await api.signIn(email: 'user@schoolable.com', password: 'password123');
    await api.completeProfile(
      employeeId: 'EMP-1',
      phone: '1234567890',
      department: 'Engineering',
      role: 'Engineer',
      dateJoined: DateTime(2024, 1, 1),
      employeeLevel: 2,
    );
  });

  test('completeProfile throws when no token is available', () async {
    final client = MockClient((request) async => http.Response('{}', 200));
    final api = BackendApiService(client: client);

    expect(
      () => api.completeProfile(
        employeeId: 'EMP-1',
        phone: '1234567890',
        department: 'Engineering',
        role: 'Engineer',
        dateJoined: DateTime(2024, 1, 1),
        employeeLevel: 2,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('getAnnouncements returns data with auth header', () async {
    final token = buildTestToken();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': token,
            'profile': {'id': 'user-1'},
          }),
          200,
        );
      }
      if (request.url.path == '/announcements') {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(
          jsonEncode([
            {'id': 'ann-1', 'title': 'Update', 'content': 'Hello team'}
          ]),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = BackendApiService(client: client);
    await api.signIn(email: 'user@schoolable.com', password: 'password123');

    final result = await api.getAnnouncements();

    expect(result, hasLength(1));
    expect(result.first['title'], 'Update');
  });

  test('getUnreadAnnouncements returns data with auth header', () async {
    final token = buildTestToken();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': token,
            'profile': {'id': 'user-1'},
          }),
          200,
        );
      }
      if (request.url.path == '/announcements/unread') {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(
          jsonEncode([
            {'id': 'ann-2', 'title': 'Unread', 'content': 'Ping'}
          ]),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = BackendApiService(client: client);
    await api.signIn(email: 'user@schoolable.com', password: 'password123');

    final result = await api.getUnreadAnnouncements();

    expect(result, hasLength(1));
    expect(result.first['id'], 'ann-2');
  });

  test('markAnnouncementAsRead posts to read endpoint', () async {
    final token = buildTestToken();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': token,
            'profile': {'id': 'user-1'},
          }),
          200,
        );
      }
      if (request.url.path == '/announcements/ann-3/read') {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(jsonEncode({'success': true}), 200);
      }
      return http.Response('Not Found', 404);
    });

    final api = BackendApiService(client: client);
    await api.signIn(email: 'user@schoolable.com', password: 'password123');

    await api.markAnnouncementAsRead('ann-3');
  });

  test('getMyComplianceItems returns items', () async {
    final token = buildTestToken();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': token,
            'profile': {'id': 'user-1'},
          }),
          200,
        );
      }
      if (request.url.path == '/compliance/my-items') {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(
          jsonEncode([
            {'id': 'policy-1', 'title': 'Policy', 'status': 'pending'}
          ]),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = BackendApiService(client: client);
    await api.signIn(email: 'user@schoolable.com', password: 'password123');

    final result = await api.getMyComplianceItems();

    expect(result, hasLength(1));
    expect(result.first['status'], 'pending');
  });

  test('submitCompliance sends upload payload', () async {
    final token = buildTestToken();
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'token': token,
            'profile': {'id': 'user-1'},
          }),
          200,
        );
      }
      if (request.url.path == '/compliance/my-items/policy-1/submit') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['type'], 'upload');
        expect(body['fileUrl'], 'https://files.example.com/doc.pdf');
        expect(body['fileName'], 'doc.pdf');
        return http.Response(jsonEncode({'status': 'submitted'}), 200);
      }
      return http.Response('Not Found', 404);
    });

    final api = BackendApiService(client: client);
    await api.signIn(email: 'user@schoolable.com', password: 'password123');

    final result = await api.submitCompliance(
      policyId: 'policy-1',
      type: 'upload',
      fileUrl: 'https://files.example.com/doc.pdf',
      fileName: 'doc.pdf',
    );

    expect(result['status'], 'submitted');
  });
}
