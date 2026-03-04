import 'package:dio/dio.dart';

void main() {
  final options = BaseOptions(baseUrl: 'https://srv1428362.hstgr.cloud/api');
  print('Base URL: \${options.baseUrl}');
  
  final uri = Uri.parse(options.baseUrl).resolve('/api/auth/login');
  print('Resolved URI with /api/auth/login: \$uri');
  
  final uri2 = Uri.parse(options.baseUrl).resolve('api/auth/login');
  print('Resolved URI with api/auth/login: \$uri2');
}
