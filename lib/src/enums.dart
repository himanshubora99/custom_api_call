enum ApiTypes { get, post, put, patch, delete }

enum CustomException {
  serverError,
  noInternet,
  timeOutError,
  tokenExpired,
  unknownError;

  String get message => switch (this) {
        CustomException.serverError => 'Server Error',
        CustomException.noInternet => 'No Internet',
        CustomException.timeOutError => 'Time Out',
        CustomException.tokenExpired => 'Token Expired.Please Login',
        CustomException.unknownError => 'Something Went Wrong',
      };
}
