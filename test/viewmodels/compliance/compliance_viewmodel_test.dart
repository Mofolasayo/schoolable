import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/compliance/compliance_view.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ComplianceViewModel Tests -', () {
    late MockBackendApiService backend;

    setUp(() {
      registerServices();
      backend = locator<BackendApiService>() as MockBackendApiService;
    });

    tearDown(() => locator.reset());

    test('fetchComplianceItems maps response into items', () async {
      when(backend.getMyComplianceItems()).thenAnswer((_) async => [
            {
              'id': 'policy-1',
              'title': 'Security Policy',
              'description': 'Keep devices encrypted',
              'type': 'policy',
              'status': 'submitted',
              'deadline': '2024-01-15',
            },
            {
              'id': 'policy-2',
              'title': 'Document Upload',
              'description': 'Upload signed document',
              'type': 'upload',
              'status': 'pending',
            },
          ]);

      final model = ComplianceViewModel();

      await model.fetchComplianceItems();

      expect(model.complianceItems, hasLength(2));
      expect(model.complianceItems.first.title, 'Security Policy');
      expect(model.complianceItems.first.status, 'submitted');
      expect(model.complianceItems.last.type, 'upload');
    });
  });
}
