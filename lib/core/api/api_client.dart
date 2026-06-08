import 'package:dio/dio.dart';
import '../api/api_exception.dart';
import '../api/endpoints.dart';
import '../models/api_response.dart';
import '../models/approval.dart';
import '../models/computer_action.dart';
import '../models/conversation_event.dart';
import '../models/cycle.dart';
import '../models/proof_package.dart';
import '../models/provider_status.dart';
import '../models/question.dart';
import '../models/screenshot.dart';
import '../models/session.dart';
import '../models/system_status.dart';
import '../models/token_usage.dart';
import '../models/ui_test_run.dart';

class ApiClient {
  late Dio _dio;
  String _baseUrl;
  String? _token;

  ApiClient({required String baseUrl, String? token})
      : _baseUrl = baseUrl,
        _token = token {
    _buildDio();
  }

  void _buildDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      },
    ));
  }

  void updateConfig({String? baseUrl, String? token}) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (token != null) _token = token;
    _buildDio();
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  Future<Map<String, dynamic>> _patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.patch(path, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException.serverUnavailable(_baseUrl);
    }
    if (e.response?.statusCode == 401) {
      return ApiException.unauthorized();
    }
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['error'] is Map<String, dynamic>) {
        return ApiException.fromMap(
          data['error'] as Map<String, dynamic>,
          statusCode: e.response?.statusCode,
        );
      }
    }
    return ApiException(
      code: 'HTTP_${e.response?.statusCode ?? 0}',
      message: e.message ?? 'Network error',
      statusCode: e.response?.statusCode,
    );
  }

  // ── System ──────────────────────────────────────────────────────────────

  Future<bool> checkHealth() async {
    try {
      final data = await _get(Endpoints.health);
      return data['ok'] == true || data['healthy'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<SystemStatus> getSystemStatus() async {
    final data = await _get(Endpoints.systemStatus);
    final resp = ApiResponse<SystemStatus>.fromJson(
      data,
      (d) => SystemStatus.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<MobileHomeData> getMobileHome() async {
    final data = await _get(Endpoints.mobileHome);
    final resp = ApiResponse<MobileHomeData>.fromJson(
      data,
      (d) => MobileHomeData.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<Map<String, dynamic>> getMobileAttention() async {
    final data = await _get(Endpoints.mobileAttention);
    return data;
  }

  // ── Sessions ─────────────────────────────────────────────────────────────

  Future<List<Session>> getSessions({String? status}) async {
    final data = await _get(Endpoints.sessions,
        params: status != null ? {'status': status} : null);
    final resp = ApiResponse<List<Session>>.fromJson(
      data,
      (d) => (d as List).map((e) => Session.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return resp.requireData;
  }

  Future<Session> getSession(String id) async {
    final data = await _get(Endpoints.session(id));
    final resp = ApiResponse<Session>.fromJson(
      data,
      (d) => Session.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<Session> createSession(Map<String, dynamic> body) async {
    final data = await _post(Endpoints.sessions, body: body);
    final resp = ApiResponse<Session>.fromJson(
      data,
      (d) => Session.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<Session> updateSession(String id, Map<String, dynamic> body) async {
    final data = await _patch(Endpoints.session(id), body: body);
    final resp = ApiResponse<Session>.fromJson(
      data,
      (d) => Session.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<void> pauseSession(String id) async {
    await _post(Endpoints.pauseSession(id));
  }

  Future<void> resumeSession(String id) async {
    await _post(Endpoints.resumeSession(id));
  }

  Future<void> stopSession(String id) async {
    await _post(Endpoints.stopSession(id));
  }

  Future<void> reopenSession(String id) async {
    await _post(Endpoints.reopenSession(id));
  }

  Future<void> deleteSession(String id) async {
    await _delete(Endpoints.deleteSession(id));
  }

  // ── Smart Sessions ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeInput(String input) async {
    final data = await _post(Endpoints.analyzeInput, body: {'input': input});
    final resp = ApiResponse<Map<String, dynamic>>.fromJson(
      data,
      (d) => d as Map<String, dynamic>,
    );
    return resp.requireData;
  }

  Future<Session> smartCreate(Map<String, dynamic> body) async {
    final data = await _post(Endpoints.smartCreate, body: body);
    final resp = ApiResponse<Session>.fromJson(
      data,
      (d) => Session.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<Session> smartCreateAndRun(Map<String, dynamic> body) async {
    final data = await _post(Endpoints.smartCreateAndRun, body: body);
    final resp = ApiResponse<Session>.fromJson(
      data,
      (d) => Session.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<List<Map<String, dynamic>>> getSessionTemplates() async {
    final data = await _get(Endpoints.sessionTemplates);
    final resp = ApiResponse<List<Map<String, dynamic>>>.fromJson(
      data,
      (d) => (d as List).cast<Map<String, dynamic>>(),
    );
    return resp.data ?? [];
  }

  // ── Cycles ────────────────────────────────────────────────────────────────

  Future<List<Cycle>> getCycles(String sessionId) async {
    final data = await _get(Endpoints.cycles(sessionId));
    final resp = ApiResponse<List<Cycle>>.fromJson(
      data,
      (d) => (d as List).map((e) => Cycle.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return resp.requireData;
  }

  Future<void> runCycle(String sessionId) async {
    await _post(Endpoints.runCycle(sessionId));
  }

  Future<void> runUntilApproved(String sessionId, {required int maxCycles}) async {
    await _post(Endpoints.runUntilApproved(sessionId), body: {'max_cycles': maxCycles});
  }

  Future<void> stopAfterCurrentCycle(String sessionId) async {
    await _post(Endpoints.stopAfterCurrentCycle(sessionId));
  }

  // ── Conversation ──────────────────────────────────────────────────────────

  Future<List<ConversationEvent>> getConversation(String sessionId) async {
    final data = await _get(Endpoints.conversation(sessionId));
    final resp = ApiResponse<List<ConversationEvent>>.fromJson(
      data,
      (d) => (d as List)
          .map((e) => ConversationEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return resp.requireData;
  }

  Future<void> postMessage(String sessionId, Map<String, dynamic> body) async {
    await _post(Endpoints.messages(sessionId), body: body);
  }

  Future<void> postNote(String sessionId, String content) async {
    await _post(Endpoints.notes(sessionId), body: {'content': content});
  }

  Future<void> postFeedback(String sessionId, Map<String, dynamic> body) async {
    await _post(Endpoints.feedback(sessionId), body: body);
  }

  // ── Questions ─────────────────────────────────────────────────────────────

  Future<List<Question>> getQuestions({String? sessionId}) async {
    final path = sessionId != null
        ? Endpoints.sessionQuestions(sessionId)
        : Endpoints.questions;
    final data = await _get(path);
    final resp = ApiResponse<List<Question>>.fromJson(
      data,
      (d) => (d as List).map((e) => Question.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return resp.requireData;
  }

  Future<void> answerQuestion(String questionId, String answer) async {
    await _post(Endpoints.answerQuestion(questionId), body: {'answer': answer});
  }

  Future<void> dismissQuestion(String questionId) async {
    await _post(Endpoints.dismissQuestion(questionId));
  }

  // ── Approvals ─────────────────────────────────────────────────────────────

  Future<List<Approval>> getApprovals({String? sessionId}) async {
    final path = sessionId != null
        ? Endpoints.sessionApprovals(sessionId)
        : Endpoints.approvals;
    final data = await _get(path);
    final resp = ApiResponse<List<Approval>>.fromJson(
      data,
      (d) => (d as List).map((e) => Approval.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return resp.requireData;
  }

  Future<void> approveApproval(String approvalId, {String? comment}) async {
    await _post(Endpoints.approveApproval(approvalId),
        body: {'comment': comment ?? ''});
  }

  Future<void> rejectApproval(String approvalId, {String? comment}) async {
    await _post(Endpoints.rejectApproval(approvalId),
        body: {'comment': comment ?? ''});
  }

  Future<void> dismissApproval(String approvalId) async {
    await _post(Endpoints.dismissApproval(approvalId));
  }

  // ── Proof ─────────────────────────────────────────────────────────────────

  Future<List<ProofPackage>> getProof({String? sessionId}) async {
    final path = sessionId != null ? Endpoints.sessionProof(sessionId) : Endpoints.proof;
    final data = await _get(path);
    final resp = ApiResponse<List<ProofPackage>>.fromJson(
      data,
      (d) => (d as List)
          .map((e) => ProofPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return resp.requireData;
  }

  // ── Tokens ────────────────────────────────────────────────────────────────

  Future<TokenSummary> getTokenSummary() async {
    final data = await _get(Endpoints.tokensSummary);
    final resp = ApiResponse<TokenSummary>.fromJson(
      data,
      (d) => TokenSummary.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<TokenUsage> getSessionTokens(String sessionId) async {
    final data = await _get(Endpoints.sessionTokens(sessionId));
    final resp = ApiResponse<TokenUsage>.fromJson(
      data,
      (d) => TokenUsage.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  // ── Providers ─────────────────────────────────────────────────────────────

  Future<List<ProviderStatus>> getProviders() async {
    final data = await _get(Endpoints.providersStatus);
    final resp = ApiResponse<List<ProviderStatus>>.fromJson(
      data,
      (d) => (d as List)
          .map((e) => ProviderStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return resp.requireData;
  }

  // ── Computer Actions ──────────────────────────────────────────────────────

  Future<List<ComputerAction>> getComputerActions({String? sessionId}) async {
    final path = sessionId != null
        ? Endpoints.sessionComputerActions(sessionId)
        : Endpoints.computerActions;
    final data = await _get(path);
    final resp = ApiResponse<List<ComputerAction>>.fromJson(
      data,
      (d) => (d as List)
          .map((e) => ComputerAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return resp.requireData;
  }

  // ── Screenshots ───────────────────────────────────────────────────────────

  Future<List<AppScreenshot>> getScreenshots({String? sessionId}) async {
    final path = sessionId != null
        ? Endpoints.sessionScreenshots(sessionId)
        : Endpoints.screenshots;
    final data = await _get(path);
    final resp = ApiResponse<List<AppScreenshot>>.fromJson(
      data,
      (d) => (d as List)
          .map((e) => AppScreenshot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return resp.requireData;
  }

  // ── UI Tests ──────────────────────────────────────────────────────────────

  Future<List<UiTestScenario>> getUiTestScenarios() async {
    final data = await _get(Endpoints.uiTestScenarios);
    final resp = ApiResponse<List<UiTestScenario>>.fromJson(
      data,
      (d) => (d as List)
          .map((e) => UiTestScenario.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return resp.data ?? [];
  }

  Future<UiTestRun> runUiTests(List<String> scenarios) async {
    final data = await _post(Endpoints.uiTestRun, body: {'scenarios': scenarios});
    final resp = ApiResponse<UiTestRun>.fromJson(
      data,
      (d) => UiTestRun.fromJson(d as Map<String, dynamic>),
    );
    return resp.requireData;
  }

  Future<List<UiTestRun>> getUiTestRuns() async {
    final data = await _get(Endpoints.uiTestRuns);
    final resp = ApiResponse<List<UiTestRun>>.fromJson(
      data,
      (d) => (d as List)
          .map((e) => UiTestRun.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return resp.data ?? [];
  }
}
