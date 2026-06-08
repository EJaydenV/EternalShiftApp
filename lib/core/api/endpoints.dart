class Endpoints {
  const Endpoints._();

  // System
  static const health = '/api/v1/health';
  static const systemStatus = '/api/v1/system/status';
  static const mobileHome = '/api/v1/mobile/home';
  static const mobileAttention = '/api/v1/mobile/attention';

  // Sessions
  static const sessions = '/api/v1/sessions';
  static String session(String id) => '/api/v1/sessions/$id';
  static String pauseSession(String id) => '/api/v1/sessions/$id/pause';
  static String resumeSession(String id) => '/api/v1/sessions/$id/resume';
  static String stopSession(String id) => '/api/v1/sessions/$id/stop';
  static String reopenSession(String id) => '/api/v1/sessions/$id/reopen';
  static String deleteSession(String id) => '/api/v1/sessions/$id';

  // Smart Sessions
  static const analyzeInput = '/api/v1/input/analyze';
  static const smartCreate = '/api/v1/sessions/smart-create';
  static const smartCreateAndRun = '/api/v1/sessions/smart-create-and-run';
  static const sessionTemplates = '/api/v1/session-templates';
  static String sessionTemplate(String id) => '/api/v1/session-templates/$id';

  // Cycles
  static String cycles(String sessionId) => '/api/v1/sessions/$sessionId/cycles';
  static String cycle(String sessionId, String cycleId) =>
      '/api/v1/sessions/$sessionId/cycles/$cycleId';
  static String runCycle(String sessionId) => '/api/v1/sessions/$sessionId/run-cycle';
  static String runUntilApproved(String sessionId) =>
      '/api/v1/sessions/$sessionId/run-until-approved';
  static String stopAfterCurrentCycle(String sessionId) =>
      '/api/v1/sessions/$sessionId/stop-after-current-cycle';

  // Conversation
  static String conversation(String sessionId) => '/api/v1/sessions/$sessionId/conversation';
  static String messages(String sessionId) => '/api/v1/sessions/$sessionId/messages';
  static String notes(String sessionId) => '/api/v1/sessions/$sessionId/notes';
  static String feedback(String sessionId) => '/api/v1/sessions/$sessionId/feedback';

  // Questions
  static const questions = '/api/v1/questions';
  static String sessionQuestions(String sessionId) => '/api/v1/sessions/$sessionId/questions';
  static String answerQuestion(String questionId) => '/api/v1/questions/$questionId/answer';
  static String dismissQuestion(String questionId) => '/api/v1/questions/$questionId/dismiss';

  // Approvals
  static const approvals = '/api/v1/approvals';
  static String sessionApprovals(String sessionId) => '/api/v1/sessions/$sessionId/approvals';
  static String approveApproval(String approvalId) => '/api/v1/approvals/$approvalId/approve';
  static String rejectApproval(String approvalId) => '/api/v1/approvals/$approvalId/reject';
  static String dismissApproval(String approvalId) => '/api/v1/approvals/$approvalId/dismiss';

  // Proof
  static const proof = '/api/v1/proof';
  static String sessionProof(String sessionId) => '/api/v1/sessions/$sessionId/proof';
  static String cycleProof(String sessionId, String cycleId) =>
      '/api/v1/sessions/$sessionId/cycles/$cycleId/proof';

  // Tokens
  static const tokensSummary = '/api/v1/tokens/summary';
  static String sessionTokens(String sessionId) => '/api/v1/sessions/$sessionId/tokens';
  static const tokensUsage = '/api/v1/tokens/usage';
  static const tokenEfficiency = '/api/v1/token-efficiency';
  static String sessionTokenEfficiency(String sessionId) =>
      '/api/v1/sessions/$sessionId/token-efficiency';

  // Providers
  static const providers = '/api/v1/providers';
  static const providersStatus = '/api/v1/providers/status';

  // Computer Actions
  static const computerActions = '/api/v1/computer-actions';
  static String sessionComputerActions(String sessionId) =>
      '/api/v1/sessions/$sessionId/computer-actions';
  static String computerAction(String actionId) => '/api/v1/computer-actions/$actionId';

  // Screenshots
  static const screenshots = '/api/v1/screenshots';
  static String sessionScreenshots(String sessionId) => '/api/v1/sessions/$sessionId/screenshots';

  // UI Tests
  static const uiTestScenarios = '/api/v1/ui-tests/scenarios';
  static const uiTestRun = '/api/v1/ui-tests/run';
  static const uiTestRuns = '/api/v1/ui-tests/runs';
  static String uiTestRunDetail(String runId) => '/api/v1/ui-tests/runs/$runId';

  // Events
  static const eventsStream = '/api/v1/events/stream';
  static String sessionEventsStream(String sessionId) =>
      '/api/v1/sessions/$sessionId/events/stream';
}
