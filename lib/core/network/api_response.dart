library;

/// Chuẩn phản hồi từ backend API ASP.NET Core: { success, message, data }
/// Tác giả: Võ Anh Tuấn - 238060244

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final bool isOfflineFallback;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.isOfflineFallback = false,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawData)? fromData,
  ) {
    final isSuccess = json['success'] == true;
    final msg = json['message']?.toString() ?? (isSuccess ? 'Thao tác thành công' : 'Đã có lỗi xảy ra');
    final rawPayload = json['data'];

    T? parsedData;
    if (rawPayload != null && fromData != null) {
      try {
        parsedData = fromData(rawPayload);
      } catch (_) {
        parsedData = null;
      }
    } else if (rawPayload != null && rawPayload is T) {
      parsedData = rawPayload;
    }

    return ApiResponse<T>(
      success: isSuccess,
      message: msg,
      data: parsedData,
      isOfflineFallback: false,
    );
  }

  factory ApiResponse.failure({
    required String message,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
      statusCode: statusCode,
      isOfflineFallback: false,
    );
  }

  factory ApiResponse.successData({
    required T data,
    String message = 'Thành công',
    int? statusCode = 200,
    bool isOfflineFallback = false,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
      isOfflineFallback: isOfflineFallback,
    );
  }

  factory ApiResponse.offlineFallback({
    required T data,
    String message = 'Dữ liệu mẫu ngoại tuyến (Máy chủ không phản hồi)',
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: null,
      isOfflineFallback: true,
    );
  }
}
