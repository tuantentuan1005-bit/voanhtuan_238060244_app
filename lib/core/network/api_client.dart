import 'package:dio/dio.dart';
import '../config.dart';
import '../storage/secure_vault.dart';
import 'api_response.dart';

/// Lớp xử lý kết nối HTTP Web API bằng Dio
/// Tự động đính kèm Bearer JWT Token từ SecureVault
/// Xử lý lỗi tập trung và trả về ApiResponse chuẩn { success, message, data }
/// Tác giả: Võ Anh Tuấn - 238060244

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final SecureVault _vault = SecureVault();

  // Callback thông báo phiên hết hạn để AuthProvider chuyển về màn hình Login
  void Function()? onSessionExpired;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-App': AppConfig.appName,
          'X-Student-Id': AppConfig.studentId,
        },
      ),
    );

    // Interceptor tự động thêm Bearer Token vào Request Header
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _vault.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Xử lý 401 Unauthorized: token hết hạn hoặc không hợp lệ
          if (error.response?.statusCode == 401) {
            await _vault.clearSession();
            onSessionExpired?.call();
          }
          return handler.next(error);
        },
      ),
    );

    // Thêm Log interceptor khi chạy debug
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  /// Cập nhật Base URL động khi cần đổi địa chỉ server mà không cần khởi động lại app
  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }

  /// GET Request bọc ApiResponse
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromData);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure(message: 'Lỗi không xác định: $e');
    }
  }

  /// POST Request bọc ApiResponse
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromData);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure(message: 'Lỗi không xác định: $e');
    }
  }

  /// PUT Request bọc ApiResponse
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromData);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure(message: 'Lỗi không xác định: $e');
    }
  }

  /// DELETE Request bọc ApiResponse
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response, fromData);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure(message: 'Lỗi không xác định: $e');
    }
  }

  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic data)? fromData,
  ) {
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      // Kiểm tra xem phản hồi có đúng format { success, message, data } không
      if (map.containsKey('success') || map.containsKey('data')) {
        return ApiResponse.fromJson(map, fromData);
      }
      // Nếu backend trả map trực tiếp
      return ApiResponse.successData(
        data: fromData != null ? fromData(map) : map as T,
        statusCode: response.statusCode,
      );
    } else if (response.data is List && fromData != null) {
      return ApiResponse.successData(
        data: fromData(response.data),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.successData(
      data: response.data as T,
      statusCode: response.statusCode,
    );
  }

  ApiResponse<T> _handleDioError<T>(DioException error) {
    String errorMessage = 'Lỗi kết nối máy chủ';
    final statusCode = error.response?.statusCode;

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      if (data['message'] != null) {
        errorMessage = data['message'].toString();
      } else if (data['title'] != null) {
        errorMessage = data['title'].toString();
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Hết thời gian chờ phản hồi từ máy chủ';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Không thể kết nối đến máy chủ (${AppConfig.apiBaseUrl}). Vui lòng kiểm tra lại mạng hoặc địa chỉ API.';
          break;
        case DioExceptionType.badResponse:
          if (statusCode == 401) {
            errorMessage = 'Phiên làm việc đã hết hạn hoặc không có quyền truy cập';
          } else if (statusCode == 403) {
            errorMessage = 'Bạn không có quyền thực hiện thao tác này';
          } else if (statusCode == 404) {
            errorMessage = 'Không tìm thấy tài nguyên yêu cầu (404)';
          } else if (statusCode != null && statusCode >= 500) {
            errorMessage = 'Máy chủ đang gặp sự cố ($statusCode)';
          } else {
            errorMessage = 'Yêu cầu không hợp lệ ($statusCode)';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Yêu cầu mạng đã bị hủy';
          break;
        default:
          errorMessage = error.message ?? 'Đã xảy ra lỗi mạng không xác định';
          break;
      }
    }

    return ApiResponse.failure(
      message: errorMessage,
      statusCode: statusCode,
    );
  }
}
