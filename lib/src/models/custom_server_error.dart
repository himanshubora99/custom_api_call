class CustomServerError {
  CustomServerError({required this.message});

  String message;

  factory CustomServerError.fromMap(Map<String, dynamic> json) =>
      CustomServerError(message: json['message'] ?? '');

  Map<String, dynamic> toMap() => <String, dynamic>{'message': message};
}
