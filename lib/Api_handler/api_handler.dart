import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';

class ApiHandler {
  double _epsilon = 0.0;
  late Dio _dio;

  double get_epsilon() => _epsilon;

  ApiHandler() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://192.168.100.33:8000',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Map<String, dynamic>> uploadAndAttack({
    required File imageFile,
    required double epsilon,
  }) async {
    try {
      _epsilon = epsilon;
      print('Epsilon set to: $_epsilon');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'epsilon': epsilon,
      });

      final response = await _dio.post(
        '/attack',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data as Map<String, dynamic>};
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {'success': false, 'error': _handleDioError(e)};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Server not responding.';
      case DioExceptionType.receiveTimeout:
        return 'Request timeout. The server took too long to respond.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode} - ${e.response?.data['message'] ?? 'Unknown error'}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return 'Connection refused. Make sure Flask server is running.';
        }
        return 'Network error: ${e.message}';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  Uint8List base64ToBytes(String base64String) {
    final cleaned = base64String.split(',').last;
    return base64Decode(cleaned);
  }
}
