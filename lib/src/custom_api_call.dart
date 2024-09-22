import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../custom_api_call.dart';

class ApiCalling {
  late Dio _dio;
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<CustomResponse> callApi(
      {required ApiTypes apiTypes,
      required String url,
      Object? data,
      Map<String, String?>? headers,
      String? jwtToken,
      ResponseType? responseType}) async {
    if (jwtToken != null) {
      final bool hasExpired = JwtDecoder.isExpired(jwtToken);
      if (hasExpired) {
        throw CustomApiException(message: CustomException.tokenExpired.message);
      }
    }
    final bool isConnected = await _networkInfo.isConnected();
    if (!isConnected) {
      throw CustomApiException(message: CustomException.noInternet.message);
    }

    try {
      Response<dynamic> response;
      _initDio(
          responseType: responseType, headers: headers, jwtToken: jwtToken);
      switch (apiTypes) {
        case ApiTypes.get:
          response = await _dio.get(url);
          break;
        case ApiTypes.post:
          response = await _dio.post(url, data: data);
          break;
        case ApiTypes.put:
          response = await _dio.put(url, data: data);
          break;
        case ApiTypes.delete:
          response = await _dio.delete(url, data: data);
          break;
        case ApiTypes.patch:
          response = await _dio.patch(url, data: data);
      }
      return CustomResponse(
          response: response, statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.response?.statusCode == 500) {
        throw CustomApiException(
            message: CustomException.serverError.message,
            statusCode: e.response?.statusCode,
            response: e.response);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw CustomApiException(
            message: CustomException.timeOutError.message,
            statusCode: e.response?.statusCode,
            response: e.response);
      }
      if (e.response != null) {
        final CustomServerError? customServerError =
            responseError(responseType: responseType, error: e.response?.data);
        throw CustomApiException(
            message: customServerError?.message ??
                CustomException.unknownError.message,
            statusCode: e.response?.statusCode,
            response: e.response);
      } else {
        throw CustomApiException();
      }
    }
  }

  CustomServerError? responseError({
    required ResponseType? responseType,
    required dynamic error,
  }) {
    CustomServerError? customServerError;
    final dynamic displayError;
    try {
      if (responseType == ResponseType.plain) {
        displayError = jsonDecode(error);
      } else {
        displayError = error;
      }
      customServerError = CustomServerError.fromMap(displayError);
      return customServerError;
    } on Exception {
      return null;
    }
  }

  void _initDio(
      {required Map<String, String?>? headers,
      required String? jwtToken,
      required ResponseType? responseType}) {
    final Map<String, String?> optionHeaders = <String, String?>{
      if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
    };
    if (headers?.isNotEmpty ?? false) {
      optionHeaders.addAll(headers!);
    }
    final BaseOptions options = BaseOptions(
        receiveTimeout: const Duration(seconds: 60),
        connectTimeout: const Duration(seconds: 60),
        headers: optionHeaders,
        responseType: responseType);
    _dio = Dio(options);
    // TODO(Himanshu): Remove it while going live.
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
        HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
  }
}

class CustomApiException implements Exception {
  String message;
  int? statusCode;
  Response<dynamic>? response;

  CustomApiException(
      {this.message = 'Something Went Wrong', this.statusCode, this.response});
}
