class SystemStatus {
  final bool healthy;
  final String? version;
  final String? uptime;
  final int? activeSessions;
  final int? runningSessions;
  final int? blockedSessions;
  final int? pendingApprovals;
  final int? pendingQuestions;
  final int? cyclesToday;
  final int? tokensToday;

  const SystemStatus({
    required this.healthy,
    this.version,
    this.uptime,
    this.activeSessions,
    this.runningSessions,
    this.blockedSessions,
    this.pendingApprovals,
    this.pendingQuestions,
    this.cyclesToday,
    this.tokensToday,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) => SystemStatus(
        healthy: json['healthy'] as bool? ?? json['ok'] as bool? ?? false,
        version: json['version'] as String?,
        uptime: json['uptime'] as String?,
        activeSessions: json['active_sessions'] as int?,
        runningSessions: json['running_sessions'] as int?,
        blockedSessions: json['blocked_sessions'] as int?,
        pendingApprovals: json['pending_approvals'] as int?,
        pendingQuestions: json['pending_questions'] as int?,
        cyclesToday: json['cycles_today'] as int?,
        tokensToday: json['tokens_today'] as int?,
      );
}

class MobileHomeData {
  final SystemStatus? systemStatus;
  final List<Map<String, dynamic>>? activeSessions;
  final List<Map<String, dynamic>>? attentionItems;
  final int? pendingApprovals;
  final int? pendingQuestions;

  const MobileHomeData({
    this.systemStatus,
    this.activeSessions,
    this.attentionItems,
    this.pendingApprovals,
    this.pendingQuestions,
  });

  factory MobileHomeData.fromJson(Map<String, dynamic> json) => MobileHomeData(
        systemStatus: json['system_status'] != null
            ? SystemStatus.fromJson(json['system_status'] as Map<String, dynamic>)
            : null,
        activeSessions: (json['active_sessions'] as List?)
            ?.cast<Map<String, dynamic>>(),
        attentionItems: (json['attention_items'] as List?)
            ?.cast<Map<String, dynamic>>(),
        pendingApprovals: json['pending_approvals'] as int?,
        pendingQuestions: json['pending_questions'] as int?,
      );
}
