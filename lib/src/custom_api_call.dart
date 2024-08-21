import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'enums.dart';
import 'models/custom_response.dart';
import 'models/custom_server_error.dart';
import 'network_info.dart';

class ApiCalling {
  late Dio _dio;
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<CustomResponse> callApi(
      {required ApiTypes apiTypes,
      required String url,
      Object? data,
      String? jwtToken,
      String? userToken,
      Map<String, String?>? optionalHeader,
      ResponseType? responseType}) async {
    bool hasExpired = false;
    if (jwtToken != null) {
      hasExpired = JwtDecoder.isExpired(jwtToken);
      print(
          'Jwt token will Expire on: ${JwtDecoder.getExpirationDate(jwtToken)}');
    }
    if (hasExpired) {
      return CustomResponse(error: CustomException.tokenExpired.message);
    }
    final bool isConnected = await _networkInfo.isConnected();
    if (!isConnected) {
      return CustomResponse(error: CustomException.noInternet.message);
    }

    try {
      Response<dynamic> response;
      _initDio(
          jwtToken: jwtToken,
          userToken: userToken,
          responseType: responseType,
          optionalHeader: optionalHeader);
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
          break;
      }
      return CustomResponse(
          response: response, statusCode: response.statusCode);
    } on DioException catch (e) {
      print(
          'DioException Response :${e.response}|| message: ${e.message} || error: ${e.error}');
      if (e.type == DioExceptionType.connectionError ||
          e.response?.statusCode == 500) {
        return CustomResponse(
            error: CustomException.serverError.message,
            statusCode: e.response?.statusCode);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return CustomResponse(
            error: CustomException.timeOutError.message,
            statusCode: e.response?.statusCode);
      }
      if (e.response?.statusCode == 400) {
        return CustomResponse(
            error: CustomException.serverError.message,
            statusCode: e.response?.statusCode);
      }
      if (e.response?.statusCode == 401) {
        return CustomResponse(
            error: 'Session TimeOut. Please login again.',
            statusCode: e.response?.statusCode);
      }
      if (e.response?.statusCode == 403) {
        return CustomResponse(
            error: 'Unauthorized', statusCode: e.response?.statusCode);
      }
      if (e.response != null) {
        final CustomServerError? customServerError =
            responseError(responseType: responseType, error: e.response?.data);
        return CustomResponse(
            response: e.response,
            statusCode: e.response?.statusCode,
            error: customServerError?.message ?? '');
      } else {
        return CustomResponse();
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
      print('CustomServerError :$displayError');
      customServerError = CustomServerError.fromMap(displayError);
      return customServerError;
    } on Exception catch (e) {
      print(e);
      return null;
    }
  }

  void _initDio(
      {required String? jwtToken,
      required String? userToken,
      required Map<String, String?>? optionalHeader,
      required ResponseType? responseType}) {
    String? authorization;
    String? userAuthToken;
    authorization = jwtToken;
    userAuthToken = userToken;
    late Map<String, String?> header;
    if (optionalHeader != null) {
      header = optionalHeader;
    } else {
      header = <String, String?>{
        'accept': 'application/json',
        'content-type': 'application/json',
        'Authorization': authorization == null ? '' : 'Bearer $authorization',
        'loginid': userAuthToken ?? '',
      };
    }
    final BaseOptions options = BaseOptions(
        receiveTimeout: const Duration(seconds: 100),
        connectTimeout: const Duration(seconds: 100),
        headers: header,
        responseType: responseType ?? ResponseType.json);
    _dio = Dio(options);
    // TODO(Himanshu): Remove it while going live.
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
        HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
    // if (Logger.mode == LogMode.debug) {
    //   _dio.interceptors.add(LoggerInterceptor());
    // }
  }
}
