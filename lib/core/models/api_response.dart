import '../api/api_exception.dart';

class ApiResponse<T> {
  final bool ok;
  final T? data;
  final String? message;
  final ApiException? error;

  const ApiResponse({
    required this.ok,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData, {
    int? statusCode,
  }) {
    if (json['ok'] == true) {
      return ApiResponse(
        ok: true,
        data: fromData != null && json['data'] != null
            ? fromData(json['data'])
            : json['data'] as T?,
        message: json['message'] as String?,
      );
    } else {
      return ApiResponse(
        ok: false,
        error: json['error'] != null
            ? ApiException.fromMap(
                json['error'] as Map<String, dynamic>,
                statusCode: statusCode,
              )
            : ApiException(
                code: 'UNKNOWN',
                message: json['message'] as String? ?? 'Unknown error',
                statusCode: statusCode,
              ),
      );
    }
  }

  T get requireData {
    if (!ok || data == null) {
      throw error ?? const ApiException(code: 'NO_DATA', message: 'No data returned');
    }
    return data as T;
  }
}
