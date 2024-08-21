class CustomServerError {
  CustomServerError({
    required this.error,
    required this.message,
  });

  String error;
  String message;

  factory CustomServerError.fromMap(Map<String, dynamic> json) =>
      CustomServerError(
        error: json['error']?.toString() ?? '',
        message: json['message'] ?? '',
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'error': error,
    'message': message,
  };
}
