import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eternal_shift_mobile/core/api/api_client.dart';
import 'package:eternal_shift_mobile/core/api/api_exception.dart';
import 'package:eternal_shift_mobile/core/models/api_response.dart';
import 'package:eternal_shift_mobile/core/models/session.dart';
import 'package:eternal_shift_mobile/core/models/approval.dart';
import 'package:eternal_shift_mobile/core/models/question.dart';
import 'package:eternal_shift_mobile/core/models/proof_package.dart';
import 'package:eternal_shift_mobile/core/config/app_config.dart';
import 'package:eternal_shift_mobile/core/api/providers.dart';
import 'package:eternal_shift_mobile/core/storage/settings_storage.dart';

void main() {
  group('ApiResponse', () {
    test('parses success response', () {
      final json = {'ok': true, 'data': {'id': '1', 'name': 'Test', 'status': 'active'}};
      final resp = ApiResponse<Session>.fromJson(
        json,
        (d) => Session.fromJson(d as Map<String, dynamic>),
      );
      expect(resp.ok, true);
      expect(resp.data?.name, 'Test');
      expect(resp.error, null);
    });

    test('parses error response', () {
      final json = {
        'ok': false,
        'error': {'code': 'SESSION_BLOCKED', 'message': 'Session is blocked.'}
      };
      final resp = ApiResponse<Session>.fromJson(json, null);
      expect(resp.ok, false);
      expect(resp.error?.code, 'SESSION_BLOCKED');
      expect(resp.data, null);
    });
  });

  group('ApiException', () {
    test('unauthorized has correct code', () {
      final e = ApiException.unauthorized();
      expect(e.code, 'UNAUTHORIZED');
      expect(e.statusCode, 401);
    });

    test('serverUnavailable contains url', () {
      final url = 'http://192.168.1.1:8765';
      final e = ApiException.serverUnavailable(url);
      expect(e.code, 'SERVER_UNAVAILABLE');
      expect(e.message, contains(url));
    });

    test('userMessage translates codes', () {
      final e = const ApiException(code: 'SESSION_BLOCKED', message: 'raw');
      expect(e.userMessage, isNot('raw'));
    });
  });

  group('Session model', () {
    test('parses from JSON', () {
      final json = {
        'id': 'sess-001',
        'name': 'Build App',
        'status': 'running',
        'provider': 'claude_cli',
        'current_task': 'Writing code',
        'cycle_count': 3,
        'total_tokens': 15000,
      };
      final s = Session.fromJson(json);
      expect(s.id, 'sess-001');
      expect(s.name, 'Build App');
      expect(s.isRunning, true);
      expect(s.isBlocked, false);
      expect(s.cycleCount, 3);
    });

    test('isBlocked returns true for blocked status', () {
      final s = Session.fromJson({'id': 'x', 'name': 'X', 'status': 'blocked'});
      expect(s.isBlocked, true);
      expect(s.isRunning, false);
    });
  });

  group('Approval model', () {
    test('parses from JSON', () {
      final json = {
        'id': 'appr-001',
        'session_id': 'sess-001',
        'requested_action': 'Execute shell command: rm -rf /tmp/test',
        'status': 'pending',
        'risk_category': 'high',
      };
      final a = Approval.fromJson(json);
      expect(a.id, 'appr-001');
      expect(a.isPending, true);
      expect(a.isApproved, false);
      expect(a.riskCategory, 'high');
    });
  });

  group('Question model', () {
    test('parses from JSON', () {
      final json = {
        'id': 'q-001',
        'session_id': 'sess-001',
        'question': 'Should I proceed with the database migration?',
        'status': 'pending',
        'is_critical': true,
      };
      final q = Question.fromJson(json);
      expect(q.id, 'q-001');
      expect(q.isPending, true);
      expect(q.isCritical, true);
    });
  });

  group('ProofPackage model', () {
    test('parses from JSON', () {
      final json = {
        'id': 'proof-001',
        'session_id': 'sess-001',
        'task': 'Build landing page',
        'status': 'passed',
        'exit_code': 0,
        'ui_tests_passed': true,
        'reviewer_verdict': 'approved',
      };
      final p = ProofPackage.fromJson(json);
      expect(p.id, 'proof-001');
      expect(p.isPassed, true);
      expect(p.isFailed, false);
      expect(p.exitCode, 0);
    });
  });

  group('AppConfig', () {
    test('has valid defaults', () {
      expect(AppConfig.defaultServerUrl, isNotEmpty);
      expect(AppConfig.defaultPollIntervalSeconds, greaterThan(0));
      expect(AppConfig.maxCyclesDefault, greaterThan(0));
      expect(AppConfig.maxCyclesMax, greaterThan(AppConfig.maxCyclesDefault));
    });
  });

  group('SettingsStorage', () {
    test('returns default server URL', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SettingsStorage(prefs);
      expect(storage.serverUrl, AppConfig.defaultServerUrl);
      expect(storage.onboardingComplete, false);
    });

    test('saves and reads server URL', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SettingsStorage(prefs);
      await storage.setServerUrl('http://192.168.1.100:8765');
      expect(storage.serverUrl, 'http://192.168.1.100:8765');
    });
  });

  group('ApiClient', () {
    test('creates client with config', () {
      final client = ApiClient(
        baseUrl: 'http://127.0.0.1:8765',
        token: 'test-token',
      );
      expect(client, isNotNull);
    });

    test('updateConfig does not throw', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8765');
      client.updateConfig(baseUrl: 'http://192.168.1.1:8765', token: 'new-token');
    });
  });
}
