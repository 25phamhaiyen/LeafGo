class ResetPasswordRequest {
  final String email;
  final String token; // Used as OTP
  final String newPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'token': token,
    'newPassword': newPassword,
  };
}
