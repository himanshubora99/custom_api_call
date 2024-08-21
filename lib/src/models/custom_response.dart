import 'package:dio/dio.dart';

class CustomResponse {
  CustomResponse({
    this.response,
    this.statusCode,
    this.error = 'Something Went Wrong',
  });

  final Response<dynamic>? response;
  final int? statusCode;
  final String error;
}
